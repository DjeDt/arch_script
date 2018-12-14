#!/bin/bash

set -e -x

main()
{
    # bug : https://bugs.archlinux.org/task/61040
    # answer : https://bbs.archlinux.org/viewtopic.php?pid=1820949#p1820949
    ln -s /tmp_lvm /run/lvm

    # replace hooks by this
    # HOOKS="base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck"
    sed -i -e '/^HOOKS/s/block/block encrypt lvm2/' /etc/mkinitcpio.conf
    mkinitcpio -v -p linux

    pacman -Sy grub --noconfirm
    grub-install --target=x86_64-efi --efi-directory=/boot/efi

    # vim /etc/default/grub
    # GRUB_CMDLINE_LINUX_DEFAULT="quiet resume=/dev/mapper/swap cryptdevice=/dev/sda3:luks_lvm"
    OPT="quiet resume=/dev/mapper/swap cryptdevice=/dev/sda3:luks_lvm"
    sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.\+\)"/GRUB_CMD_LINE_DEFAULT="$OPT"/g' /etc/default/grub

    dd if=/dev/urandom of=/crypto_keyfile.bin  bs=512 count=10
    chmod 000 /crypto_keyfile.bin
    chmod 600 /boot/initramfs-linux*
    cryptsetup luksAddKey /dev/sda3 /crypto_keyfile.bin

    # Now include /crypto_keyfile.bin file under FILES directive in mkinicpio.conf file.
    #    FILES=/crypto_keyfile.bin
    sed -i -e '/FILES=()/a\' -e 'FILES="/crypto_keyfile.bin"' /etc/mkinitcpio.conf

    # Regenerate ramdisk file.
    mkinitcpio -p linux

    # Regenerate grub.cfg file:
    #######################################
    ## Erreur ici, pas de grub.cfg
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg
    #######################################

    # setup root password
    passwd
    exit
}

main
