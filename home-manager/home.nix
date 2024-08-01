
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


  programs.home-manager.enable = true;

  imports = [
    # ./modules/alacritty/alacritty.nix
    ./modules/bat.nix
    ./modules/clangd/clangd.nix
    ./modules/git/git.nix
    ./modules/i3lock/i3lock.nix
    ./modules/kitty/kitty.nix
    ./modules/lazygit/lazygit.nix
    ./modules/librewolf/librewolf.nix
    ./modules/pylint/pylint.nix
    ./modules/qtile/qtile.nix
    # ./modules/ranger/ranger.nix
    ./modules/rofi/rofi.nix
    ./modules/starship/starship.nix
    ./modules/stylua/stylua.nix
    ./modules/themes/catppuccin.nix
    ./modules/themes/qt.nix
    ./modules/themes/gtk.nix
    ./modules/tmux/tmux.nix
    ./modules/yazi/yazi.nix
    ./modules/zsh/zsh.nix
  ];
}
