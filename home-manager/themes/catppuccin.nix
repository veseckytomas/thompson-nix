{ config, pkgs, ... }:

{
  catppuccin = {
    flavor = "mocha";
    accent = "mauve";
    catppuccin.pointerCursor = {
      enable = true;
      flavor = "mocha";
      flavor = "mauve";
    };
  };
  gtk.catppuccin = {
    enable = true;
    acent = "mauve";
    flavor = "mocha";
    size = "standard";
    icon = {
      enable = true;
      accent = "mauve";
      flavor = "mocha";
    };
  };
}
