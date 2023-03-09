#!/bin/bash
if [ "$EUID" -ne 0 ]
then
  echo "You must be root in order to install the VM"
  exit 1
fi

if ! command -v virt-install &>/dev/null || ! command -v libvirtd &>/dev/null;
then
  echo "Please install libvirt and virt-install"
  exit 2
fi

if [ -z $1 ]
then
	domain="unassigned-domain"
else
	domain=$1
fi

wget -c -q --show-progress "https://cdimage.debian.org/debian-cd/current/amd64/iso-dvd/debian-11.4.0-amd64-DVD-1.iso"

create_iso () {
	MOUNTED_PATH=$(mktemp -d)
	COPY_PATH=$(mktemp -d)

	mount -o loop debian-11.4.0-amd64-DVD-1.iso $MOUNTED_PATH
	cp -r $MOUNTED_PATH/* $COPY_PATH

	cp preseed.cfg $COPY_PATH/preseed.cfg
	cp post-install.sh $COPY_PATH/post-install.sh
	cp install.sh $COPY_PATH/install.sh
	sed -i "s/\$domain/$domain/g" $COPY_PATH/preseed.cfg

	mkisofs $COPY_PATH -o debian-preseed.iso
	rm -rf $COPY_PATH
	umount $MOUNTED_PATH
}

#create_iso
#exit

#iname=$(ip -o link show | sed -rn '/^[0-9]+: en/{s/.: ([^:]*):.*/\1/p}')
iname="wlp2s0"
virt-install \
	--name nextcloud \
	--description "Nextcloud server on debian" \
	--ram=4096 \
	--vcpus=2 \
	--os-variant=debian11 \
	--autostart \
	--location="debian-11.4.0-amd64-DVD-1.iso" \
	--initrd-inject preseed.cfg \
	--initrd-inject post-install.sh \
	--extra-args="ks=file:/preseed.cfg domain=$domain" \
	--noautoconsole --wait

# --network type=direct,source=$iname,source_mode=bridge,model=virtio \
# --location="http://ftp.fr.debian.org/debian/dists/bullseye/main/installer-amd64/"

#nextcloud_ip=$(virsh net-dhcp-leases default | grep nextcloud | awk '{ print $5 }' | awk 'BEGIN{FS="[/]"}{print $1}')
#echo "VM ip is : $nextcloud_ip"
echo "Vm install"
echo "Root Password is 'root'. "
echo "To get VM ip use 'virsh net-dhcp-leases default'"
