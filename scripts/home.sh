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

echo "Please touch the device."
git pull
git add --all
home-manager switch --flake .#vesecto
if test $? != 0; then
	echo "Build failed"
	git restore --staged :/ >/dev/null
	exit 1
fi
git commit -m "Home-manager $(date -Iseconds)"
echo "Please touch the device."
git push
