#!/bin/bash

set -e -x

BASE_PACKAGE="efibootmgr grub-efi-x86_64 os-prober linux-headers linux-firmware wpa_supplicant dialog git"
HOSTNAME="l4tpt0p"
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
    # replace hooks by thisx
    sed -i -e '/^HOOKS/s/block/block keymap encrypt lvm2/' /etc/mkinitcpio.conf
    # generate initrd image
    mkinitcpio -p linux

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck

    OPT="cryptdevice=/dev/sda3:luks_lvm quiet"
    sed -i "s|GRUB_CMDLINE_LINUX_DEFAULT=\(.\+\)|GRUB_CMDLINE_LINUX_DEFAULT=\"$OPT\"|g" /etc/default/grub

    # Regenerate grub.cfg file:
    grub-mkconfig -o /boot/grub/grub.cfg
}

CORE="xf86-video-amdgpu mesa xorg xorg-xinit xterm openbox dunst compton tint2 termite nitrogen thunar tmux arc-solid-gtk-theme volumeicon networkmanager network-manager-applet alsa-utils"
TOOLS="weechat emacs git obconf lxappearance bash-completion xbindkeys xf86-input-synaptics firefox"
EXTRA="vlc evince i3lock gcc make radare2 gdb radare2-cutter noto-fonts openssh openssl tar unzip redshift wget curl strace openvpn dnscrypt-proxy macchanger"
conf_install()
{
	pacman -Sy $CORE
	pacman -Sy $TOOLS
	pacman -Sy $EXTRA
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
