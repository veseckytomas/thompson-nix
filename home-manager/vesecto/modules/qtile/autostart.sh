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
nm-applet &
xbacklight -set 50
xset s off -dpms
amixer set Master off
"$HOME"/.screenlayout.sh &
sleep 1

distro=$(grep ^ID /etc/os-release | head -n1 | cut -d'=' -f2)
if [ "$distro" = "arch" ]; then
    feh --bg-fill "$HOME/.config/backgrounds/arch_background.jpg" &
elif [ "$distro" = "nixos" ]; then
    feh --bg-fill "$HOME/.config/backgrounds/nixos_background.png" &
else
    feh --bg-fill "$HOME/.config/backgrounds/linux_background.jpg" &
fi
