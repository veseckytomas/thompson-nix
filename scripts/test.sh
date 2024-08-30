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

RED="\033[1;91m"
NC="\033[0;0m"

echo -e "${RED}Please touch the device. (Pull)${NC}"
git pull
git add --all
sudo nixos-rebuild test --flake .#
if test $? != 0; then
    echo "Build failed"
fi
git restore --staged :/ >/dev/null
