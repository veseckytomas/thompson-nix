#!/usr/bin/env bash
#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
distro=$(grep ^ID /etc/os-release | head -n1 | cut -d'=' -f2)
if [ "$distro" = "arch" ]; then
    feh --bg-fill "$HOME/.config/backgrounds/arch_background.jpg" &
elif [ "$distro" = "nixos" ]; then
    feh --bg-fill "$HOME/.config/backgrounds/nixos_background.png" &
else
    feh --bg-fill "$HOME/.config/backgrounds/linux_background.jpg" &
fi
