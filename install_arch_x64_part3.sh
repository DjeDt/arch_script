#!/bin/bash

set -e -x

USER="dje"
#GRAPH_PACK="openbox tint2 nitrogen git obconf lxappearance-obconf lxinput thunar acpi rofi emacs i3lock dunst ncmpcpp mpc urxvt-unicode xorg-server xorg-init iw"
GRAPH_PACK="openbox acpi alsa-utils cmatrix arandr arc-gtk-theme xorg xinit obconf"
PROG_PACK="dunst compton feh noto-fonts noto-fonts-emoji glances htop ranger rofi git tint2 libnotify imagemagick volumeicon iw ncmpcpp mpc"
DEV_PACK="make gcc gdb peda python emacs python termite"
ANON_PACK="firefox tor torify macchanger"

graphical_conf()
{
    pacman -Sy \
	   $GRAPH_PACK \
	   $PROG_PACK \
	   $DEV_PACK \
	   $ANON_PACK

    if [ -d "$HOME/.config" ] ; then
	mv "$HOME/.config" "$HOME/.config.bkp"
    fi
    
    git clone https://github.com/djedt/dotfiles.git "$HOME/.config_git"
    echo "exec openbox-session" >> "/$HOME/.xinitrc"
    openbox --reconfigure
}

main()
{
    graphical_conf
}

main
