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

nix run nixpkgs#python3Packages.pip cache purge
find "$HOME" -name '.direnv' -exec rm -r {} \;
sudo nix-collect-garbage -d
sudo /run/current-system/bin/switch-to-configuration boot
nix-collect-garbage -d
nix-store --optimize
"$HOME/.tmux/plugins/tpm/bin/clean_plugins"
docker system prune -af --volumes
trash-empty -f --all-users
