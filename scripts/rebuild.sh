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

echo "Please touch the device."
git pull
git add --all
sudo nixos-rebuild switch --flake .#
if test $? != 0; then
  echo "Build failed"
  git restore --staged :/ >/dev/null
  exit 1
fi
home-manager switch --flake .#vesecto
if test $? != 0; then
  echo "Home-manager build failed"
  git restore --staged :/ >/dev/null
  exit 1
fi
gen=$(nixos-rebuild list-generations | grep current | cut -d' ' -f1)
git commit -m "$(hostname): Gen $gen"
echo "Please touch the device."
git push
