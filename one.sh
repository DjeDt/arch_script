#!/bin/bash

set -e -x

ENCRYPT_FORMAT="aes-xts-plain64"
HASH_FORMAT="sha512"
KEY_SIZE="512"
PBKDF="argon2id"
PBKDFIT=42
PBKDFMEM=1048576

encrypt_volume()
{
    # cryptsetup luksFormat -v -s 512 -h sha512 /dev/sda3
    cryptsetup --cipher "$ENCRYPT_FORMAT" \
	       --key-size "$KEY_SIZE" \
	       --hash "$HASH_FORMAT" \
	       --pbkdf=$PBKDF \
	       --pbkdf-force-iterations $PBKDFIT \
	       --pbkdf-memory $PBKDFMEM \
	       --use-random \
	       --verify-passphrase luksFormat /dev/sda3

    cryptsetup open --type luks /dev/sda3 luks_lvm

}

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


ROOT_SIZE="60G"
SWAP_SIZE="8G"
HOME_SIZE="100%free"
prepare_logical_volume()
{
    modprobe dm-crypt
    modprobe dm-mod
    
    encrypt_volume

    # configure lvm
    pvcreate /dev/mapper/luks_lvm
    vgcreate arch /dev/mapper/luks_lvm

    lvcreate -L $ROOT_SIZE arch -n root
    lvcreate -L $SWAP_SIZE arch -n swap
    lvcreate -l $HOME_SIZE arch -n home

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
    #  mkdir -p /mnt/tmp_lvm
    #  mount --bind /run/lvm /mnt/tmp_lvm
}

install_basics()
{
    pacstrap /mnt base base-devel
    genfstab -Up /mnt >> /mnt/etc/fstab
}

SEC_STEP="two.sh"
main()
{
    create_partition
    prepare_logical_volume
    format_partition
    mount_partition
    install_basics

    # go to part2
    if [ ! -f "$SEC_STEP" ] ; then
	echo "Error: '$SEC_STEP' not found - do ya chroot shit alone"
	exit 2
    fi
    cp "$SEC_STEP" /mnt/
    arch-chroot /mnt ./"$SEC_STEP"
    rm "/mnt/$SEC_STEP"
    umount -R /mnt
    swapoff -a

    echo "== Install done. =="
}

main
