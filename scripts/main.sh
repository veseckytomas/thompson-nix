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

echo "Choose which action to perform:"
echo "1. Rebuild (Default)"
echo "2. Update"
echo "3. Garbage collect"
echo "4. Exit"

read -r input

case $input in
"2")
	./scripts/update.sh
	;;
"3")
	./scripts/clean.sh
	;;
"4")
	echo "Exiting..."
	;;
*)
	./scripts/rebuild.sh
	;;
esac
