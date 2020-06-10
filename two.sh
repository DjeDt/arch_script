#!/bin/bash

set -e -x

BASE_PACKAGE="efibootmgr grub-efi-x86_64 lvm2 linux linux-hardened os-prober linux-hardened-headers linux-firmware wpa_supplicant dialog git dhcpcd"
HOSTNAME="dOz"
basic_conf()
{
    pacman -Sy reflector
    # find fatest mirrors
    reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
    # update db
    pacman -Syu

    # install base package
    pacman -Sy $BASE_PACKAGE

    # set system clock
    ln -sf /user/share/zoneinfo/UTC /etc/localtime
    hwclock --systohc --utc
    timedatectl set-ntp true

    # set Hostname
    echo "$HOSTNAME" >> /etc/hostname

    # Setup langage
    sed -i -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    locale-gen
}

USER="dje"
create_user()
{
    # setup root password
    passwd

    # create user
    useradd -m -G wheel -s /bin/bash "$USER"
    passwd "$USER"

    # allow sudo to wheel group
    sed -i '/%wheel ALL=(ALL) ALL/s/^#//' /etc/sudoers
}

mkinit_n_grub()
{
    # replace hooks
    sed -i -e '/^HOOKS/s/block/block keymap encrypt lvm2/' /etc/mkinitcpio.conf
    
    # generate initrd image
    mkinitcpio -p linux
    mkinitcpio -p linux-hardened

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck

    # fix amd encryption conflict with hardened kernel by setting off mem_encrypt to off
    OPT="cryptdevice=/dev/sda3:luks_lvm quiet mem_encrypt=off"
    sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\(.\+\)|GRUB_CMDLINE_LINUX_DEFAULT=\"$OPT\"|g" /etc/default/grub

    # Regenerate grub.cfg file:
    grub-mkconfig -o /boot/grub/grub.cfg
}

# if intel : use xf86-video-intel

SYSTEM="xf86-video-amdgpu mesa xorg xorg-xinit xterm alsa-utils xf86-input-synaptics"
FONTS="ttf-font-awesome ttf-nerd-fonts-symbols noto-fonts"
VISUAL="openbox i3 dunst compton tint2 arc-solid-gtk-theme volumeicon nitrogen thunar obconf lxappearance i3lock"
PROG="termite tmux networkmanager network-manager-applet emacs git bash-completion firefox bash-completion evince \
gcc make gdb openssh openssl tar unzip wget curl openvpn dnscrypt-proxy macchanger dnsutils keepass"

conf_install()
{
    pacman -Sy --noconfirm $SYSTEM $FONTS $VISUAL $PROG
}

main()
{
    basic_conf
    create_user
    mkinit_n_grub
    conf_install
    exit
}

main
