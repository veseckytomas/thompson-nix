#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas

{ config, pkgs, ... }:

{
  home.username = "vesecto";
  home.homeDirectory = "/home/vesecto";
  home.stateVersion = "24.05";

  home.sessionVariables = {
    EDITOR = "nvim";
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  # home.activation

  news.display = "silent";
  programs.home-manager.enable = true;

  imports = [
    # Directories
    ./modules/clangd/clangd.nix
    ./modules/git/git.nix
    ./modules/i3lock/i3lock.nix
    ./modules/qtile/qtile.nix
    # ./modules/ranger/ranger.nix
    ./modules/rofi/rofi.nix
    ./modules/starship/starship.nix
    ./modules/stylua/stylua.nix
    ./modules/themes/catppuccin.nix
    ./modules/themes/gtk.nix
    ./modules/themes/qt.nix
    ./modules/tmux/tmux.nix
    ./modules/zsh/zsh.nix

    # Single files
    # ./modules/alacritty.nix
    ./modules/atuin.nix
    # ./modules/autorandr.nix
    ./modules/bat.nix
    ./modules/editorconfig.nix
    ./modules/kitty.nix
    ./modules/lazygit.nix
    ./modules/librewolf.nix
    ./modules/pylint.nix
    ./modules/yazi.nix
  ];
}
