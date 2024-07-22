#!/usr/bin/env bash
#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas

### AUTOSTART PROGRAMS ###
picom --daemon &
nm-applet &
xbacklight -set 50
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
