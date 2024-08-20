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
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Directories
    ./clangd/clangd.nix
    ./git/git.nix
    ./i3lock/i3lock.nix
    ./qtile/qtile.nix
    # ./ranger/ranger.nix
    ./rofi/rofi.nix
    ./starship/starship.nix
    ./stylua/stylua.nix
    ./themes/catppuccin.nix
    ./themes/gtk.nix
    ./themes/qt.nix
    ./tmux/tmux.nix
    ./zsh/zsh.nix

    # Single files
    # ./alacritty.nix
    ./atuin.nix
    # ./autorandr.nix
    ./bat.nix
    ./editorconfig.nix
    ./fzf.nix
    ./kitty.nix
    ./lazygit.nix
    ./librewolf.nix
    ./nvim/nvim.nix
    ./pandoc.nix
    ./pylint.nix
    ./yazi.nix
  ];
}
