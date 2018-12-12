#!/bin/bash

set -e

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
	   mkpart ESP fat32 1MiB 200MiB \
	   set 1 boot on \
	   name 1 efi \
	   \
	   mkpart primary 200MiB 800MiB \
	   name 2 boot \
	   \
	   mkpart primary 800MiB 100% \
	   set 3 lvm on \
	   name 3 lvm \
	   print
}


SECOND_PART="install_arch_x64_part2.sh"
prepare_logical_volume()
{
    modprobe dm-crypt
    modprobe dm-mod
    cryptsetup luksFormat -v -s 512 -h sha512 /dev/sda3
    cryptsetup open /dev/sda3 luks_lvm

    # configure lvm
    pvcreate /dev/mapper/luks_lvm
    vgcreate arch /dev/mapper/luks_lvm
    lvcreate -n root -L 10G arch
    lvcreate -n home -L 10G arch
    lvcreate -n swap -L 1G -C y arch
}

format_partition()
{
    # format partitions
    mkfs.fat -F32 /dev/sda1
    mkfs.ext4 /dev/sda2
    mkfs.btrfs -L root /dev/mapper/arch-root
    mkfs.btrfs -L home /dev/mapper/arch-home
    mkswap /dev/mapper/arch-swap
}

mount_partition()
{
    #  mount
    swapon /dev/mapper/arch-swap
    swapon -a
    swapon -s
    mount /dev/mapper/arch-root /mnt
    mkdir -p /mnt/{home,boot}
    mount /dev/sda2 /mnt/boot
    mount /dev/mapper/arch-home /mnt/home
    mkdir /mnt/boot/efi
    mount /dev/sda1 /mnt/boot/efi
}

PACSTRAP_BASE_PACKAGE=" base base-devel efibootmgr vim dialog xterm btrfs-progs grub"
install_basics()
{
    pacstrap /mnt "$PACSTRAP_BASE_PACKAGE" --noconfirm
    genfstab -Up /mnt > /mnt/etc/fstab
}

main()
{
    create_partition
    prepare_logical_volume
    format_partition
    install_basics

    # go to part2
    if [ ! -f "$SECOND_PART" ] ; then
	echo "error: '$SECOND_PART' not found - do ya chroot shit alone"
    else
	cp -a "$SECOND_PART" /mnt
	arch-chroot /mnt ./"$SECOND_PART"
	umount -R /mnt
	reboot
    fi
}

main
