{ config, pkgs, ... }:

{
  home.username = "vesecto";
  home.homeDirectory = "/home/vesecto";
  home.stateVersion = "24.05";

  # packages
  # home.packages = [
  # ];

  # File
  # home.file = {
  # };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;

  imports = [
    # ./modules/alacritty/alacritty.nix
    # ./modules/bash/bash.nix
    ./modules/bat/bat.nix
    ./modules/zsh/zsh.nix
  ];
}
