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

echo "Please touch the device. (Pull)"
git pull
git add --all
mkdir -p build
nix run nixpkgs#nixos-generators -- --format iso --flake .#rescueIso -o build/rescue
if test $? != 0; then
    echo "Rescue ISO build failed"
fi
nix run nixpkgs#nixos-generators -- --format iso --flake .#installIso -o build/install
if test $? != 0; then
    echo "Install ISO build failed"
fi
git restore --staged :/ >/dev/null
