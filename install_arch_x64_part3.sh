#!/bin/bash

LAST_PACKAGE="openbox tint2 nitrogen git obconf lxappearance-obconf lxinput thunar compton"
MAYBE="obkey"
graphical_conf()
{
    pacman -Sy $LAST_PACKAGE

    # configure openbox
    cp /etc/X11/xinit/xinitrc /home/$USER/.xinitrc
    echo "exec openbox-session" >> /home/$USER/.xinitrc
    echo "[[ -z $DISPLAY && $XDG_VTNR -eq 1 ]] && exec startx" >> /home/$USER/.bashrc

    cp -R /etc/xdg/openbox /home/$USER/.config

    openbox --reconfigure
    echo <<EOF
tint2 & \
nitrogen --restore & \
compton -b -c & \
thunar --daemon &
EOF
}

main()
{
    graphical_conf
}

main
