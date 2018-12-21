#!/bin/bash

set -e -x

PACMAN_PACKAGE="efibootmgr grub-efi-x86_64 os-prober linux-headers linux-lts linux-lts-headers wpa_supplicant dialog git"
HOSTNAME="laptop"
USER="dje"
basic_conf()
{
    # install base package
    pacman -S $PACMAN_PACKAGE

    # set system clock
    ln -sf /user/share/zoneinfo/UTC /etc/localtime
    hwclock --systohc --utc

    # set Hostname
    echo "$HOSTNAME" >> /etc/hostname

    # Setup langage
    sed -i -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    locale-gen
}

create_user()
{
    # setup rootpassword
    passwd

    # create user
    useradd -m -G wheel -s /bin/bash "$USER"
    passwd "$USER"

    # allow sudo to wheel group
    sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
}

mkinit_n_grub()
{
    # replace hooks by thisx
    sed -i -e '/^HOOKS/s/block/block keymap encrypt lvm2/' /etc/mkinitcpio.conf
    # generate initrd image
    mkinitcpio -p linux
    mkinitcpio -p linux-lts
    
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck

    OPT="cryptdevice=/dev/sda3:luks_lvm quiet"
    sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\(.\+\)|GRUB_CMDLINE_LINUX_DEFAULT=\"$OPT\"|g" /etc/default/grub

    # Regenerate grub.cfg file:
    grub-mkconfig -o /boot/grub/grub.cfg
}

main()
{
    # bug : https://bugs.archlinux.org/task/61040
    # fix : https://bbs.archlinux.org/viewtopic.php?pid=1820949#p1820949
    ln -sf /tmp_lvm /run/lvm

    basic_conf
    create_user
    mkinit_n_grub
    
    exit
}

main
