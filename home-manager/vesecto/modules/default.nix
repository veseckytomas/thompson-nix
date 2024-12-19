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
{...}: {
  imports = [
    # ./alacritty.nix
    ./atuin.nix
    # ./autorandr.nix
    ./backgrounds
    ./bat.nix
    ./clangd
    ./editorconfig.nix
    ./fzf.nix
    ./git
    ./hyprland
    ./i3lock
    ./nomacs
    ./kitty.nix
    ./lazygit.nix
    ./librewolf.nix
    ./nvim
    ./pandoc.nix
    ./picom.nix
    ./pylint.nix
    ./qtile
    # ./ranger
    ./rofi
    ./starship
    ./statix
    ./stylua
    ./themes
    ./tmux
    ./yazi.nix
    # ./zoxide.nix
    ./zsh
  ];
}
