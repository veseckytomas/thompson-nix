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

git restore --staged :/ >/dev/null
git add home-manager
home-manager switch --flake .#vesecto
if test $? != 0; then
    echo "Build failed"
    git restore --staged :/ >/dev/null
    exit 1
fi
gen=$(home-manager generations | head -1 | cut -d' ' -f5)
echo -e "${RED}Please touch the device. (Sign commit)${NC}"
git commit -m "Home-manager $(hostname): Gen $gen"
echo -e "${RED}Please touch the device. (Push)${NC}"
git push
