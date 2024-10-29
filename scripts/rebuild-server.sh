#!/usr/bin/env bash
#   _______
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas

git pull
sudo nixos-rebuild switch -j 8 --cores 8 --flake /home/vesecto/Git/thompson-nix#
if [ "$(uname -m)" = "aarch64" ]
then
  home-manager switch --flake /home/vesecto/Git/thompson-nix#vesecto-server-arm
else
  home-manager switch --flake /home/vesecto/Git/thompson-nix#vesecto-server
fi
exit 0
