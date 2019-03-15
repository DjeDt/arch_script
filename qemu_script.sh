#!/bin/bash

DWN_PATH="./"
FILE_IMAGE="archlinux-2019.03.01-x86_64.iso"

set -e -x

check_integrity()
{
	smd5="8164667750c46cf297720b21145e1e27"
	ssha1="e32acb5a7b7cfb2bdba10697cce48ab69e13c186"

    cmd5=$(md5sum -z "$DWN_PATH/$FILE_IMAGE" | awk {'print $1'})
    csh1=$(sha1sum -z "$DWN_PATH/$FILE_IMAGE" | awk {'print $1'})
    if [[ "$smd5" != "$cmd5" ]] ; then
		echo "fatal error md5 chesksum differs"
		echo "MD5 : from web   : -> $smd5"
		echo "MD5 : from file  : -> $cmd5"
		exit 2
    fi
    if  [[ "$ssha1" != "$csh1" ]] ; then
		echo "fatal error sha1 chesksum differs"
		echo "SHA1 : from web  : -> $ssha1"
		echo "SHA1 : from file : -> $csh1"
		exit 2
    fi
	echo "Checksum are ok."
}

Q_IMAGE="arch_image.img"
SIZE_IMAGE=30G
RAM_ALLOWED=2G
create_image()
{
    qemu-img create -f qcow2 "$Q_IMAGE" "$SIZE_IMAGE"
}

main()
{
	check_integrity
	if [ ! -f "$Q_IMAGE" ] ; then
		create_image
    fi
	#qemu-system-x86_64 -cdrom "$DWN_PATH/$FILE_IMAGE" -boot order=d -drive file="$DWN_PATH/$FILE_IMAGE" format=raw -m "$RAM_ALLOWED" -net nic -net user,hostfwd=tcp::10022-:22

    qemu-system-x86_64 -enable-kvm -m "$RAM_ALLOWED" \
					   -hda "$Q_IMAGE" -boot d -cdrom "$DWN_PATH/$FILE_IMAGE" \
					   -net nic -net user,hostfwd=tcp::10022-:22
}

main
#
# TO USE INSTALL SCRIPT ON VM WITH QEMU :
#	-> inside the vm after boot and root login
#	-> $> systemctl start sshd
#	-> $> passwd (set tmp root passwd)
#
#	-> from the host:
#	-> scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -P 10022 one.sh two.sh root@localhost:/tmp
