#!/bin/sh

# Used to debug in chroot

cryptsetup open --type luks /dev/sda3 luks_lvm

mount /dev/mapper/arch-root /mnt
mkdir -p /mnt/boot
mount /dev/sda2 /mnt/boot
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi
mkdir -p /mnt/home
mount /dev/mapper/arch-home /mnt/home
swapon /dev/mapper/arch-swap
arch-chroot /mnt /bin/bash
