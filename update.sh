#!/usr/bin/env bash

nix flake update
sudo nixos-rebuild switch --flake .#
sudo nix-collect-garbage --delete-older-than 5d
