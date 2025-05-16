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

pushd /thompson-nix > /dev/null || exit
git pull
nixos-rebuild switch --flake .#
if [ "$(uname -m)" = "aarch64" ]
then
  home-manager switch --flake .#vesecto-server-arm
else
  home-manager switch --flake .#vesecto-server
fi
popd || exit
exit 0
