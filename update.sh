#!/usr/bin/env bash

nix flake update
sudo nixos-collect-garbage --delete-older-than 5d
./rebuild.sh
