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
  imports = [
    # Directories
    ./plugins/chatgpt/chatgpt.nix

    # Single file
    ./plugins/alpha.nix
    ./plugins/codeium-nvim.nix
    ./plugins/codesnap.nix
    ./plugins/comment.nix
    ./plugins/copilot-chat.nix
    ./plugins/copilot-vim.nix
    ./plugins/gitsigns.nix
    ./plugins/lualine.nix
    ./plugins/nvim-autopairs.nix
  ];
}

