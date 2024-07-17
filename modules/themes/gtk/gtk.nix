{ config, pkgs, ... }:

let
  gruvboxPlus = import ./gruvbox-plus.nix { inherit pkgs; };
in 
{
  gtk = {
    enable = true;
    cursorTheme = {
      name = "Catppuccin-Mocha-Light-Cursors";
      package = pkgs.catppuccin-cursors.mochaLight;
      size = 16;
    };
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "GruvboxPlus";
      package = gruvboxPlus;
    };
  };
}
