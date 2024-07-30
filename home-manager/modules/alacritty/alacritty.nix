{ config, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;
    catppuccin = {
      enable = true;
      flavor = "mocha";
    };
  };
  home.file.".config/alacritty/alacritty.toml".source = ./alacritty.toml;
}
