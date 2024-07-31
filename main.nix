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

{ config, pkgs, lib, ... }:

{
  imports =
    [
      ./modules/audio/pipewire.nix
      ./modules/bootLoaders/systemd-boot.nix
      ./modules/common/common.nix
      # ./modules/common/gaming.nix
      ./modules/common/locale.nix
      ./modules/common/packages.nix { inherit lib; }
      ./modules/common/users.nix
      ./modules/loginManagers/sddm.nix
      ./modules/virtualisation/virt-manager.nix
      ./modules/virtualisation/virtualbox.nix
      ./modules/windowManagers/qtile.nix



      # ./modules/windowManagers/awesome.nix
      # ./modules/windowManagers/cinnamon.nix
      # ./modules/windowManagers/enlightenment.nix
      ./modules/windowManagers/gnome.nix
      # ./modules/windowManagers/i3.nix
      # ./modules/windowManagers/plasma.nix
      # ./modules/windowManagers/xfce.nix
      # ./modules/windowManagers/xmonad.nix
    ];
}
