#!/bin/bash

set -e -x


HOSTNAME="4rch_l4pt0p"
USER="dje"
main()
{

    # set system clock
    ln -s /user/share/zoneinfo/UTC / etc/localtime
    hwclock --systohc --utc

    # set Hostname
    echo "$HOSTNAME" >> /etc/hostname


    # Setup langage
    sed -i -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/local.gen
    locale-gen

    # setup rootpassword
    passwd

    # create user
    useradd -m -G wheel -s /bin/bash "$USER"
    passwd "$USER"

    # bug : https://bugs.archlinux.org/task/61040
    # answer : https://bbs.archlinux.org/viewtopic.php?pid=1820949#p1820949
    ln -s /tmp_lvm /run/lvm

    # replace hooks by this
    # HOOKS="base udev autodetect modconf block encrypt lvm2 filesystems keyboard fsck"
    sed -i -e '/^HOOKS/s/block/block encrypt lvm2/' /etc/mkinitcpio.conf

    # generate initrd image
    mkinitcpio -v -p linux

    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux --recheck

    # vim /etc/default/grub
    # GRUB_CMDLINE_LINUX_DEFAULT="quiet resume=/dev/mapper/swap cryptdevice=/dev/sda3:luks_lvm"
    OPT="quiet resume=/dev/mapper/swap cryptdevice=/dev/sda3:luks_lvm"
    sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.\+\)"/GRUB_CMD_LINE_DEFAULT="$OPT"/g' /etc/default/grub

    # allow grub to boot on from luks encrypted devices
    sed -i -e 's\^#GRUB_ENABLE_CRYPTODISK=y\GRUB_ENABLE_CRYPTODISK=y\g'

#    dd if=/dev/urandom of=/crypto_keyfile.bin  bs=512 count=10
#    chmod 000 /crypto_keyfile.bin
#    chmod 600 /boot/initramfs-linux*
#    cryptsetup luksAddKey /dev/sda3 /crypto_keyfile.bin

    # Now include /crypto_keyfile.bin file under FILES directive in mkinicpio.conf file.
    #    FILES=/crypto_keyfile.bin
    sed -i -e '/FILES=()/a\' -e 'FILES="/crypto_keyfile.bin"' /etc/mkinitcpio.conf

    # Regenerate ramdisk file.
    mkinitcpio -p linux

    # Regenerate grub.cfg file:
    #######################################
    ## Erreur ici, pas de grub.cfg
    grub-mkconfig -o /boot/grub/grub.cfg
#    grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg
    #######################################

    exit
}

main
