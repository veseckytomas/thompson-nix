{ config, pkgs, ... }:

{
  imports =
    [
      ./modules/audio/pipewire.nix
      ./modules/bootLoaders/grub.nix
      ./modules/common/common.nix
      ./modules/common/locale.nix
      ./modules/common/packages.nix
      ./modules/common/users.nix
      ./modules/loginManagers/sddm.nix
      ./modules/virtualisation/virt-manager.nix
      ./modules/virtualisation/virtualbox.nix
      ./modules/windowManagers/gnome.nix
      ./modules/windowManagers/qtile.nix
    ];
}
