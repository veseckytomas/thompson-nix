{ config, pkgs, lib, ... }:

{
  programs.bash.enable = true;
  home.file.".zshrc".source = ./zshrc;
  home.file.".config/zsh/header.txt".source = ./header.txt;
  home.file.".config/zsh/catppuccin_mocha-zsh-syntax-highlighting.zsh".source = ./catppuccin_mocha-zsh-syntax-highlighting.zsh;
}
