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
sudo nixos-rebuild boot -j 8 --cores 8 --flake .#"$hostname"
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
git clone git@gitlab.com:vesecky.tomas/thompson-nix.git "$HOME/Git/thompson-nix"
git clone git@gitlab.com:vesecky.tomas/obsidian.git "$HOME/Git/thompson-obsidian"
git clone git@gitlab.com:homelab1960731/thompson-dwh.git "$HOME/DataGripProjects/Homelab"
git clone git@gitlab.fit.cvut.cz:vesecto1/dwh-project.git "$HOME/DataGripProjects/DWH"

# Clone TPM repository
git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# Install eduroam
nix-shell -p 'python311.withPackages(ps: with ps; [ dbus-python ])' --run "python3 ./data/eduroam-linux-eduroam_-_settings.py"

# Install proton compatibility layer
if which protonup &> /dev/null; then
  protonup
fi
