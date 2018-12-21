#!/bin/bash

set -e -x

USER="dje"

GRAPH_PACK="openbox acpi alsa-utils cmatrix arandr arc-gtk-theme xorg-server xorg-xinit obconf nvidia-lts"
PROG_PACK="dunst compton feh noto-fonts noto-fonts-emoji glances htop ranger rofi git tint2 libnotify imagemagick volumeicon iw ncmpcpp mpc"
DEV_PACK="make gcc gdb peda python emacs python termite"
ANON_PACK="firefox tor macchanger"

graphical_conf()
{
    sudo pacman -Sy $GRAPH_PACK
    sudo pacman -Sy $PROG_PACK
    sudo pacman -Sy $DEV_PACK
    sudo pacman -Sy $ANON_PACK
    git clone https://github.com/djedt/dotfiles.git "$HOME/.config_git"
}

main()
{
    graphical_conf
}

main
