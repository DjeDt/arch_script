#!/bin/bash

FILE_IMAGE="archlinux-2018.10.01-x86_64.iso"
DWN_PATH="qemu/arch"

set -e -x

download_image()
{
    if [[ ! -f "$DWN_PATH/$FILE_IMAGE" ]] ; then
	wget "https://mirror.cyberbits.eu/archlinux/iso/2018.10.01/archlinux-2018.10.01-x86_64.iso" -O "$DWN_PATH/$FILE_IMAGE"
    fi
}

check_integrity()
{
    smd5=$(curl -s https://mirror.cyberbits.eu/archlinux/iso/2018.10.01/md5sums.txt | head -n1 | awk {'print $1'})
    ssha1=$(curl -s https://mirror.cyberbits.eu/archlinux/iso/2018.10.01/sha1sums.txt | head -n1 | awk {'print $1'})

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
    else
	echo "md5 & sha1 cheksum are ok: boot qemu"
    fi
}

Q_IMAGE="arch_image.img"
SIZE_IMAGE=50G
RAM_ALLOWED=1G
create_image()
{
    qemu-img create -f qcow2 "$Q_IMAGE" "$SIZE_IMAGE"
}

main()
{

    download_image
    if [ ! -f "$Q_IMAGE" ] ; then
	create_image
    fi
    check_integrity
#qemu-system-x86_64 -cdrom "$DWN_PATH/$FILE_IMAGE" -boot order=d -drive file="$DWN_PATH/$FILE_IMAGE" format=raw -m "$RAM_ALLOWED" -net nic -net user,hostfwd=tcp::10022-:22

    qemu-system-x86_64 -enable-kvm -m "$RAM_ALLOWED" \
		       -drive if=pflash,format=raw,readonly,file=/usr/share/ovmf/x64/OVMF_CODE.fd \
		       -drive if=pflash,format=raw,file=my_uefi_vars.bin \
		       -hda "$Q_IMAGE" -boot d -cdrom "$DWN_PATH/$FILE_IMAGE" \
		       -net nic -net user,hostfwd=tcp::10022-:22
}

main
#
# TO USE INSTALL SCRIPT ON VM WITH QEMU :
#	-> inside the vm after boot and root login
#	-> $> pacman -Sy openssh && systemctl enable sshd && systemctl start sshd
#	-> $> passwd (set tmp root passwd)
#
#	-> from the host:
#	-> scp -o "StrictHostKeyChecking=no" -o "UserKnownHostsFile=/dev/null" -P 10022 install_arch_x64{.sh,_part2.sh} root@localhost:/tmp
