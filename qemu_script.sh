#!/bin/sh

FILE_IMAGE="archlinux-2018.10.01-x86_64.iso"
DWN_PATH="qemu/arch"

usage()
{
    printf "./qemu_script.sh [-...]\n"
    printf "\t-f : arch file.img"
    exit $1
}

download_img()
{
    while true ; do
	read -p "have i to download arch image ? [yY/nN]: " rep
	case "$rep" in
	    y|Y)
		#wget "https://mirror.cyberbits.eu/archlinux/iso/2018.10.01/archlinux-2018.10.01-x86_64.iso" -O "$FILE_IMAGE"
		FILE_IMAGE="downloaded_image"
		return 0
		;;
	    n|N)
		printf "then i have to abort.\n"
		exit 0
	    ;;
	    *)
		printf "i need something else.\n"
	    ;;
	esac
    done
    return 1
}

if [ "$1" ] ; then
    if [ ! -f "$1" ] ; then
	printf "$1 is not a valid file.\n"
	download_img
	if [ $? -ne 0 ] ; then
	    exit 1
	fi
    else
	FILE_IMAGE="$1"
    fi
elif [ ! -f "$FILE_IMAGE" ] ; then
    printf "basic file image not found.\n"
    download_img
    if [ $? -ne 0 ] ; then
	exit 1
    fi
fi

printf "Checking checksum :\n"
smd5=$(curl -s https://mirror.cyberbits.eu/archlinux/iso/2018.10.01/md5sums.txt | head -n1 | awk {'print $1'})
cmd5=$(md5sum -z "$FILE_IMAGE" | awk {'print $1'})
if [[ "$smd5" != "$cmd5" ]] ; then
    printf "fatal error md5 chesksum differs. abort.\n"
    exit 2
else
    printf "md5 : OK\n"
fi

ssha1=$(curl -s https://mirror.cyberbits.eu/archlinux/iso/2018.10.01/sha1sums.txt | head -n1 | awk {'print $1'})
csh1=$(sha1sum -z "$FILE_IMAGE" | awk {'print $1'})
if  [[ "$ssha1" != "$csh1" ]] ; then
    printf "fatal error sha1 chesksum differs. abort\n"
    exit 2
else
    printf " sha1 : OK\n"
fi

read -p "launch the iso in a virtual machine using qemu? [yY/nN] :" rep
case "$rep" in
    y|Y)
    ;;
    *)
	printf "i'm stopping here\n"
	exit 0
    ;;
esac

Q_IMAGE="arch_image.img"
SIZE_IMAGE="30G"
RAM_ALOWED="1024"
printf "Creating image : "
qemu-img create "$Q_IMAGE" "$SIZE_IMAGE"
if [ $? -eq 0 ] ; then
    printf "OK\n"
else
    printf "Error: qemu-img create failed.\n"
    exit 1
fi

printf "Launching qemu :\n"
qemu-system-x86_64 \
    -hda "$Q_IMAGE" -boot d -cdrom "$DWN_PATH/$FILE_IMAGE" -m "$RAM_ALOWED" \
    -net nic -net user,hostfwd=tcp::10022-:22

#
# TO USE INSTALL SCRIPT ON VM WITH QEMU :
#	-> inside the vm after boot and root login
#	-> $> pacman -Sy openssh && systemctl enable sshd && systemctl start sshd
#	-> $> passwd (set tmp root passwd)
#
#	-> from the host:
#	-> $> scp -P 10022 install_arch_x64.sh root@localhost:/tmp/install.sh
