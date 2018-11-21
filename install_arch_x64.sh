#!/bin/sh

ENCRYPT_FORMAT="aes-xts-plain64"
HASH_FORMAT="sha512"
KEY_SIZE="512"
encrypt_volume()
{
    cryptsetup --cipher "$ENCRYPT_FORMAT" --key-size "$KEY_SIZE" --hash "$HASH_FORMAT" --iter-time 5000 --use-random \
	       --verify-passphrase luksFormat /dev/sda2
    cryptsetup open --type luks /dev/sda2 crypt
#    cryptsetup luksOpen /dev/sda2 luks
}

LVM_SWAP_SIZE="8"
LVM_ROOT_SIZE="80G"
LVM_USER_SIZE="+100%FREE"
LVM_VOLUME_GROUP_NAME="vg0"
create_lvm_partition()
{
    pvcreate "/dev/mapper/luks"
    vgcreate "$LVM_VOLUME_GROUP_NAME" /dev/mapper/luks


    lvcreate -L "$LVM_SWAP_SIZE" "$LVM_VOLUME_GROUP_NAME" -n swap
    lvcreate -L "$LVM_ROOT_SIZE" "$LVM_VOLUME_GROUP_NAME" -n root
    lvcreate -L "$LVM_USER_SIZE" "$LVM_VOLUME_GROUP_NAME" -n users
#    lvcreate --size "$LVM_SWAP_SIZE" "$LVM_VOLUME_GROUP_NAME" --name swap
#    lvcreate --size "$LVM_ROOT_SIZE" "$LVM_VOLUME_GROUP_NAME" --name root
#    lvcreate --size "$LVM_USER_SIZE" "$LVM_VOLUME_GROUP_NAME" --name users

    # format these partitions
    mkfs.ext4 /dev/mapper/"$LVM_VOLUME_GROUP_NAME"-root
    mkfs.ext4 /dev/mapper/"$LVM_VOLUME_GROUP_NAME"-users
    mkswap /dev/mapper/"$LVM_VOLUME_GROUP_NAME"-swap
}

mount_system()
{
    mount /dev/mapper/"$LVM_VOLUME_GROUP_NAME"-root /mnt
    mkdir -p /mnt/boot
    mount /dev/sda1 /mnt/boot
    swapon /dev/mapper/"$LVM_VOLUME_GROUP_NAME"-swap
}

TIMEZONE_AREA="Europe/Paris"
LOCALE_VAL="en_US.UTF-8 UTF-8"
LANG_VALUE="en_US.UTF-8"
HOSTNAME_VALUE="johndoe"
LOCAL_DOMAIN="blublu"
USER_NAME="user"
BASE_PACKAGE="base base-devel openssh git vim grub"
ADDON_PACKAGE="emacs dialog wpa_supplicant termit"
setup_filesystem()
{

    # install base system
    pacstrap -i /mnt "$BASE_PACKAGE"
    
    # set timezone
    ln -s /usr/share/zoneinfo/"$TIMEZONE_AREA" /etc/localtime

    # set Locale (keybord binding)
    # A verifier
    # sed -i s/#"$LOCALE_VAL"/"$LOCALE_VAL"/g /etc/locale.gen
    locale-gen
    echo "LANG=$LANG_VALUE" > /etc/locale.conf
    export LANG="$LANG_VALUE"

    # set hardware clock the same as the operating system to avoid
    # time shifts problems
    hwclock --systohc --utc

    # set Hostname
    echo "$HOSTNAME_VALUE" > /etc/hostname

    # set virtualhost (local)
    echo "127.0.1.1 $HOSTNAME_VALUE.$LOCAL_DOMAIN $HOSTNAME_VALUE" >> /etc/hosts


    # install package used required
    pacman -Suy "$USER_PACKAGE"
    
    # Create user
    useradd -m -g users -G wheel -s "$USERNAME"
    passwd "$USERNAME" << EOF
$USER_PASSWORD
EOF
    # set visudo
    # to-do

    # cnfigure mkinitcpio with needed modules for the initrd image
    # add 'ext4' to MODULES
    # add 'encrypt and 'lvm2' to HOOKS before 'filesystems'

    # Reload initrd image
    # mkinitcpio -p linux
    
    # Setup grub and create bootloader
    grub-install && grub-mkconfig
}



VOL_GROUP="Vol"
secure_disk_erase()
{
    # 1st arg is the partition to clean
    cryptsetup open --type plain -d /dev/urandom /dev/$1 to_be_wiped

    dd if=/dev/zero of=/dev/mapper/to_be_wiped status=progress

    cryptsetup close to_be_wiped
}

create_partition()
{
    sfdisk /dev/sda -uM <<EOF
,1,256M,83
,2,10G,83
,3,18G,83
EOF
}

prepare_logical_volume()
{
    # Create logical group
    pvcreate "$VOL_GROUP" /dev/sda2
    vgcreate "$VOL_GROUP" /dev/sda2
    lvcreate -L 32G -n cryptroot "$VOL_GROUP"
    lvcreate -L 500M -n cryptswap "$VOL_GROUP"
    lvcreate -L 500M -n crypttmp "$VOL_GROUP"
    lvcreate -l 100%FREE -n crypthome "$VOL_GROUP"

    cryptsetup luksFormat --type luks2 /dev/$VOL_GROUP/cryptroot
    cryptsetup open /dev/$VOL_GROUP/cryptroot root
    mkfs.ext4 /dev/mapper/root
    mount /dev/mapper/root /mnt

    # Boot partition
    dd if=/dev/zero of=/dev/sda1 bs=1M status=progress
    mkfs.ext4 /dev/sda1
    mkdir /mnt/boot
    mount /dev/sda1 /mnt/boot
}

main()
{
    create_partition
    exit 1

    prepare_logical_volume
    # formating partition
#    mkfs.ext4 /dev/sda1

#    encrypt_volume

#    create_lvm_partition

#    mount_system

    # Install base system + package
#    install_base_system

#    setup_filesystem
    # generate fstab so the file '/etc/fstab' file is used to define how
    # partisions, rmeote filesystem, usb device..
    # should be mounted into the filesystem
#    genfstab -pU >> /mnt/etc/fstab

    # to generate /tmp as a ramdisk uncomment this
    # echo "tmpfs /tmp tmpfs default,noatime,mode=1777 0 0" >> /mnt/etc/fstab

    # chroot into the filesystem
#    arch-chroot /mnt /bin/bash
    
#    setup_filesystem
}

main
