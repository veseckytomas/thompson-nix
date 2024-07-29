{ config, pkgs, ... }:

{
  programs.alacritty.enable = true;
  home.file."alacritty.toml".source = ./alacritty.toml;
}
