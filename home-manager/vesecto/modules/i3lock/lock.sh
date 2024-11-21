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

setxkbmap -layout us
distro=$(grep ^ID /etc/os-release | head -n1 | cut -d'=' -f2)
if [ "$distro" = "arch" ]; then
    i3lock -kti "$HOME"/.config/i3lock/arch_lock_screen.png
elif [ "$distro" = "nixos" ]; then
    i3lock -kti "$HOME"/.config/i3lock/nixos_lock_screen.png
else
    i3lock -kti "$HOME"/.config/i3lock/linux_lock_screen.png
fi
