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

read -r -p "Clean boot partition? [y/N] " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]
then
  sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 14d
fi

read -r -p "Clean Pip cache? [y/N] " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]
then
  nix run nixpkgs#python3Packages.pip cache purge
fi

read -r -p "Clean dev shells? [y/N] " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]
then
  # find "$HOME" -name '.direnv' -exec rm -r {} \; 2> /dev/null
  fd -HI ^\.direnv$ "$HOME" -E .git -E Trash -X rm -r
fi


read -r -p "Clean nix-store? [y/N] " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]
then
  rm -rf ~/.local/share/nvim/mason
  sudo nix-collect-garbage -d
  sudo /run/current-system/bin/switch-to-configuration boot
  nix-collect-garbage -d
  nix-store --optimize
fi

read -r -p "Prune docker cache? [y/N] " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]
then
  docker system prune -af --volumes
fi

read -r -p "Empty trash? [y/N] " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]
then
  trash-empty -f --all-users
fi
