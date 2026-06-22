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
"${BASH_SOURCE%/*}/update-oh-my-openagent.sh"

# Update LibreWolf to the latest upstream binary release. Decoupled from the
# (unmaintained) nixpkgs librewolf package; see
# modules/common/packages/librewolf-bin.nix.
librewolf_json="modules/common/packages/librewolf-bin.json"
librewolf_latest=$(curl -H 'accept: application/json' -sL https://codeberg.org/api/v1/repos/librewolf/bsys6/releases/latest | jq -r '.tag_name')
librewolf_current=$(jq -r '.version' "$librewolf_json" 2>/dev/null)
if [ -z "$librewolf_latest" ] || [ "$librewolf_latest" = "null" ]; then
    echo -e "${RED}LibreWolf: could not fetch latest version, keeping $librewolf_current.${NC}"
elif [ "$librewolf_latest" = "$librewolf_current" ]; then
    echo "LibreWolf: already up-to-date ($librewolf_current)"
else
    librewolf_sum=$(curl -sfL "https://codeberg.org/api/packages/librewolf/generic/librewolf/$librewolf_latest/librewolf-$librewolf_latest-linux-x86_64-package.tar.xz.sha256sum" | awk '{print $1}')
    if [ -z "$librewolf_sum" ]; then
        echo -e "${RED}LibreWolf: could not fetch checksum for $librewolf_latest, keeping $librewolf_current.${NC}"
    else
        librewolf_hash=$(nix --extra-experimental-features 'nix-command' hash convert --to sri --hash-algo sha256 "$librewolf_sum")
        printf '{\n  "version": "%s",\n  "hash": "%s"\n}\n' "$librewolf_latest" "$librewolf_hash" >"$librewolf_json"
        echo "LibreWolf: $librewolf_current -> $librewolf_latest"
    fi
fi

git restore --staged :/

git add flake.lock
git add home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/oh-my-openagent-bun.nix
git add "$librewolf_json"

echo -e "${RED}Please touch the device. (Sign commit)${NC}"
git commit -m "Update lockfiles"
if ! "${BASH_SOURCE%/*}/rebuild.sh"; then
    exit 1
fi
if ! "${BASH_SOURCE%/*}/home.sh"; then
    exit 1
fi
