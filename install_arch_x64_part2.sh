#!/bin/bash

set -e -x

HOSTNAME="4rch_l4pt0p"
USER="dje"
main()
{

    sync
    # bug : https://bugs.archlinux.org/task/61040
    # fix : https://bbs.archlinux.org/viewtopic.php?pid=1820949#p1820949
    ln -sf /tmp_lvm /run/lvm

    # set system clock
    ln -sf /user/share/zoneinfo/UTC /etc/localtime
    hwclock --systohc --utc

    # set Hostname
    echo "$HOSTNAME" >> /etc/hostname

    # Setup langage
    sed -i -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
    locale-gen

    # setup rootpassword
    passwd

    # create user
    useradd -m -G wheel -s /bin/bash "$USER"
    passwd "$USER"

    # replace hooks by this
    # HOOKS="base udev autodetect modconf block keymap encrypt lvm2 resume filesystems keyboard fsck"
    #    sed -i -e '/^HOOKS/s/block/block keymap encrypt lvm2 resume/' /etc/mkinitcpio.conf
    sed -i -e '/^HOOKS/s/base/base btrfs udev autodetect modconf block keymap encrypt lvm2 resume filesystem keyboard fcsk'

    # generate initrd image
    mkinitcpio -p linux

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck

    # vim /etc/default/grub
    # GRUB_CMDLINE_LINUX_DEFAULT="quiet resume=/dev/mapper/swap cryptdevice=/dev/sda3:luks_lvm"
    OPT="quiet resume=/dev/mapper/swap cryptdevice=/dev/mapper:luks_lvm"
    sed -e 's/GRUB_CMDLINE_LINUX=\(.\+\)/GRUB_CMDLINE_LINUX="cryptdevice=\/dev\/sda3:arch-root root=/dev/mapper/arch-root resume=\/dev\/mapper\/arch-swap"/g' /etc/default/grub

    # Regenerate grub.cfg file:
    grub-mkconfig -o /boot/grub/grub.cfg
    exit
}

main
