#!/bin/bash
if [ "$EUID" -ne 0 ]; then
  echo "You must be root in order to install the VM"
  exit 1
fi

if ! command -v virt-install &>/dev/null || ! command -v libvirtd &>/dev/null;
then
  echo "Please install libvirt and virt-install"
  exit 1
fi

wget -c -q --show-progress "https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-11.4.0-amd64-DVD-1.iso"


#iname=$(ip -o link show | sed -rn '/^[0-9]+: en/{s/.: ([^:]*):.*/\1/p}')
iname="wlp2s0"
virt-install \
	--name nextcloud \
	--description "Nextcloud server on debian" \
	--ram=4096 \
	--vcpus=2 \
	--os-variant=debian11 \
	--autostart \
	--cdrom "debian-11.4.0-amd64-DVD-1.iso" \
	--initrd-inject preseed.cfg \
	--extra-args="ks=file:/preseed.cfg console=tty0 console=ttyS0,115200"

# --network type=direct,source=$iname,source_mode=bridge,model=virtio \
# --location="http://ftp.fr.debian.org/debian/dists/bullseye/main/installer-amd64/"

