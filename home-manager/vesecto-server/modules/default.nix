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
    # Directories
    ./nvim/nvim.nix
    ./starship/starship.nix
    ./tmux/tmux.nix
    ./zsh/zsh.nix

    # Single files
    ./atuin.nix
    ./editorconfig.nix
    ./fzf.nix
    ./git.nix
  ];
}
