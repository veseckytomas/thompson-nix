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

nix flake update

"${BASH_SOURCE%/*}/update-gemini-auth.sh"
"${BASH_SOURCE%/*}/update-oh-my-openagent.sh"

git restore --staged :/
git add flake.lock
git add home-manager/vesecto/modules/opencode/plugins/lockfiles
echo -e "${RED}Please touch the device. (Sign commit)${NC}"
git commit -m "Update flake.lock"
if "${BASH_SOURCE%/*}/rebuild.sh"; then
    git reset origin/master
    exit 1
fi
if "${BASH_SOURCE%/*}/home.sh"; then
    git reset origin/master
    exit 1
fi
