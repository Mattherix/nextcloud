#!/bin/bash
# This script is run at the end of the install in the chrooted environnement by the preseed

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
