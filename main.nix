{ config, pkgs, ... }:

{
  imports =
    [
      ./modules/common/common.nix
      ./modules/common/locale.nix
      ./modules/common/packages.nix
      ./modules/common/users.nix
      ./modules/loginManagers/sddm.nix
      ./modules/windowManagers/gnome.nix
      ./modules/windowManagers/qtile.nix
      # ./modules/themes/theme.nix
    ];
}
