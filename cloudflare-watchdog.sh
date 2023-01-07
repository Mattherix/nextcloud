#!/bin/bash
# https://github.com/cloudflare/cloudflared/issues/278

# Get cloudflared first PID
pid=$(pidof -s cloudflared)

# If no pid, just start cloudflared and end
if [ -z "$pid" ]; then
    echo "No process running so starting"
    (/usr/local/bin/cloudflared --config /root/.cloudflared/config.yml --no-autoupdate tunnel run) &
    exit 0
fi

# Get process age and don't do anything if less than 5 minutes old. xargs on its own acts like trim()
seconds=$(ps -p ${pid} -o etimes= | xargs)
if [ "${seconds}" -lt 300 ]; then
    echo "too young"
    exit 0
fi

# Get status from metrics server
status=$(curl -s http://localhost:8099/ready | jq -r '.status')

# If status is 503, we don't have any active connections so restart
if [ "${status}" == "503" ]; then
    echo "cloudflared appears to be down, restarting"
    killall cloudflared

    # Wait two minutes
    sleep 120

    # And then kill them all just in case
    killall -9 cloudflared

    # And restart
    (/usr/local/bin/cloudflared --config /root/.cloudflared/config.yml --no-autoupdate tunnel run) &
    exit 0
fi

# Everything is runing, so nothing to do
exit 0
