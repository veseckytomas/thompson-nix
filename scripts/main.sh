#!/usr/bin/env bash

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
