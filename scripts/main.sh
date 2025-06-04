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

RED="\033[1;91m"
NC="\033[0;0m"

echo "Choose which action to perform:"
echo "1. Rebuild (Default)"
echo "2. Home-manager"
echo "3. Rebuild Test"
echo "4. Update"
echo "5. Garbage collect"
echo "6. Setup"
echo "7. Generate ISO"
echo "8. Garbage collect (full)"
echo "9. Exit"

read -r input

if [ "$input" != "5" ] && [ "$input" != "8" ] && [ "$input" != "9" ]; then
    echo -e "${RED}Please touch the device. (Pull)${NC}"
    git pull
fi

case $input in
    "2")
        ./scripts/home.sh
        ;;
    "3")
        ./scripts/test.sh
        ;;
    "4")
        ./scripts/update.sh
        ;;
    "5")
        ./scripts/clean.sh
        ;;
    "6")
        ./scripts/setup.sh
        ;;
    "7")
        ./scripts/gen-iso.sh
        ;;
    "8")
        yes | ./scripts/clean.sh
        ;;
    "9")
        echo "Exiting..."
        ;;
    *)
        if ! ./scripts/rebuild.sh; then
            exit 1
        fi
        ./scripts/home.sh
        ;;
esac
