#!/usr/bin/env bash

### AUTOSTART PROGRAMS ###
picom --daemon &
nm-applet &
# "$HOME"/.screenlayout/set_layout.sh &
# sleep 1

distro=$(hostnamectl | grep 'System' | cut -d' ' -f3)
if [ "$distro" = "Arch" ]; then
	feh --bg-fill "$HOME/.config/qtile/images/arch_background.jpg" &
elif [ "$distro" = "NixOS" ]; then
	feh --bg-fill "$HOME/.config/qtile/images/nixos_background.png" &
else
	feh --bg-fill "$HOME/.config/qtile/images/linux_background.jpg" &
fi
