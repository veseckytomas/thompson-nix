{ config, pkgs, ... }:

{
  catppuccin = {
    flavor = "mocha";
    accent = "mauve";
    pointerCursor = {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
    };
  };
  gtk.catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
    size = "standard";
    icon = {
      enable = true;
      flavor = "mocha";
      accent = "mauve";
    };
  };
  qt.style.catppuccin = {
    enable = true;
    apply = true;
    flavor = "mocha";
    accent = "mauve";
  };
}
