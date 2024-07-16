#!/usr/bin/env bash

git add --all
sudo nixos-rebuild switch --flake .#
if test $? != 0; then
	echo "Build failed"
	git restore --staged :/
	return 1
fi
gen=$(nixos-rebuild list-generations | grep current | cut -d' ' -f1)
git commit -m "$(hostname): Gen $gen"
git push
