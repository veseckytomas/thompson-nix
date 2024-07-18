#!/usr/bin/env bash

distro=$(hostnamectl | grep 'System' | cut -d' ' -f3)
if [ "$distro" = "Arch" ]; then
	i3lock -kti $HOME/.config/i3lock/arch_lock_screen.png
elif [ "$distro" = "NixOS" ]; then
	i3lock -kti $HOME/.config/i3lock/nixos_lock_screen.png
else
	i3lock -kti $HOME/.config/i3lock/linux_lock_screen.png
fi
