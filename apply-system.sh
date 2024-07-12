#!/bin/sh

if [ "$1" = "" ]; then
	host="TomasVesa-NTB2-NixOS"
else
	host="$1"
fi

pushd ~/NixOS
sudo nixos-rebuild switch -I nixos-config="./hosts/$host/configuration.nix"
popd
