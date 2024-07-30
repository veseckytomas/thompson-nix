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
    ./catppuccin.nix
    # ./modules/alacritty/alacritty.nix
    ./modules/bat.nix
    ./modules/clangd/clangd.nix
    # ./modules/fish/fish.nix
    ./modules/zsh/zsh.nix
  ];
}
