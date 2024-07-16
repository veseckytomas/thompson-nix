#!/usr/bin/env bash

nix flake update
sudo nixos-rebuild switch --flake .#
sudo nix-env --delete-generations +5
./rebuild.sh
