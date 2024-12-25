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

echo "Enter hostname:"
read -r hostname

# Rebuild system
sudo nixos-rebuild switch -j 8 --cores 8 --flake .#"$hostname"
nix-shell -p home-manager --run "home-manager switch --flake .#$(whoami)"

# Insert Yubikeys
if ! ls "$HOME/.config/Yubico/u2f_keys" &> /dev/null; then
  mkdir -p "$HOME/.config/Yubico"
  echo "Insert first Yubikey and press enter"
  read -r
  pamu2fcfg > "$HOME/.config/Yubico/u2f_keys"
  echo "Insert second Yubikey and press enter"
  read -r
  pamu2fcfg -n >> "$HOME/.config/Yubico/u2f_keys"
fi

# Clone repositories
git clone git@gitlab.com:vesecky.tomas/thompson-nix.git "$HOME/Git/Personal/thompson-nix"
git clone git@gitlab.com:vesecky.tomas/thompson-obsidian.git "$HOME/Git/Personal/thompson-obsidian"
git clone git@gitlab.com:vesecky.tomas/thompson-notes.git "$HOME/Git/Personal/thompson-notes"
git clone git@gitlab.com:homelab1960731/thompson-dwh.git "$HOME/DataGripProjects/Homelab"
git clone git@gitlab.fit.cvut.cz:vesecto1/dwh-project.git "$HOME/DataGripProjects/DWH"

# Install eduroam
curl "https://cat.eduroam.org/user/API.php?action=downloadInstaller&lang=en&profile=2904&device=linux&generatedfor=user&openroaming=0" > eduroam.py
nix-shell -p 'python311.withPackages(ps: with ps; [ dbus-python ])' --run "python3 ./eduroam.py"
rm eduroam.py

# Install proton compatibility layer
if which protonup &> /dev/null; then
  protonup
fi
