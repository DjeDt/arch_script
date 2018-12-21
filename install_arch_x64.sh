#!/bin/bash

set -e -x

#ENCRYPT_FORMAT="aes-xts-plain64"
#HASH_FORMAT="sha512"
#KEY_SIZE="512"
#encrypt_volume()
#{
#    cryptsetup --cipher "$ENCRYPT_FORMAT" --key-size "$KEY_SIZE" --hash "$HASH_FORMAT" --iter-time 5000 --use-random \
#	       --verify-passphrase luksFormat /dev/sda2
#    cryptsetup open --type luks /dev/sda2 crypt
##    cryptsetup luksOpen /dev/sda2 luks
#}
#
#VOL_GROUP="Vol"
#secure_disk_erase()
#{
#    # 1st arg is the partition to clean
#    cryptsetup open --type plain -d /dev/urandom /dev/$1 to_be_wiped
#    dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress
#    cryptsetup close to_be_wiped
#}

create_partition()
{
    parted --script /dev/sda \
	   mklabel gpt \
	   mkpart ESP fat32 1MiB 300MiB \
	   set 1 boot on \
	   name 1 efi \
	   \
	   mkpart primary 300MiB 700MiB \
	   name 2 boot \
	   \
	   mkpart primary 700MiB 100% \
	   set 3 lvm on \
	   name 3 lvm \
	   print
}

prepare_logical_volume()
{
    modprobe dm-crypt
    modprobe dm-mod

    cryptsetup luksFormat -v -s 512 -h sha512 /dev/sda3
    cryptsetup open --type luks /dev/sda3 luks_lvm

    # configure lvm
    pvcreate /dev/mapper/luks_lvm
    vgcreate arch /dev/mapper/luks_lvm

    lvcreate -L 15G arch -n root
    lvcreate -L 4G arch -n swap
    lvcreate -l 100%free arch -n home

    vgscan
    vgchange -ay arch
}

format_partition()
{
    # format partitions
    # efi partition
    mkfs.fat -F32 /dev/sda1

    # boot partition
    mkfs.ext4 -F /dev/sda2

    # root + home + swap
    mkfs.ext4 /dev/mapper/arch-root
    mkfs.ext4 /dev/mapper/arch-home
    mkswap /dev/mapper/arch-swap
}

mount_partition()
{
    #  mount
    mount /dev/mapper/arch-root /mnt

    mkdir -p /mnt/boot
    mount /dev/sda2 /mnt/boot

    mkdir -p /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi

    mkdir -p /mnt/home
    mount /dev/mapper/arch-home /mnt/home

    swapon /dev/mapper/arch-swap

    # bug : https://bugs.archlinux.org/task/61040
    # fix : https://bbs.archlinux.org/viewtopic.php?pid=1820949#p1820949
    mkdir -p /mnt/tmp_lvm
    mount --bind /run/lvm /mnt/tmp_lvm
}

PACSTRAP_BASE_PACKAGE="base base-devel"
install_basics()
{
    pacstrap /mnt $PACSTRAP_BASE_PACKAGE
    genfstab -Up /mnt >> /mnt/etc/fstab
}

SEC_STEP="install_arch_x64_part2.sh"
TRI_STEP="install_arch_x64_part3.sh"
main()
{
    create_partition
    prepare_logical_volume
    format_partition
    mount_partition
    install_basics

    # go to part2
    if [ ! -f "$TRI_STEP" ] ; then
	echo "error: '$TRI_STEP' not found - do ya chroot shit alone"
    else
	cp "$SEC_STEP" "$TRI_STEP" /mnt/
	arch-chroot /mnt ./"$SECOND_PART"
	rm "/mnt/$SEC_STEP"
    	umount -R /mnt
	swapoff -a
	echo "dont forget to run the 3rd script after reboot : [cd / && ./$TRI_STEP]" && sleep 2
	reboot
    fi
}

main
