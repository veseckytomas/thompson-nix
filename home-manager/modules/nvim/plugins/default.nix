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
    ./alpha.nix
    ./chatgpt/chatgpt.nix
    ./codeium-nvim.nix
    ./codesnap.nix
    ./comment.nix
    ./copilot-chat.nix
    ./copilot-vim.nix
    ./gitsigns.nix
    ./indent-blankline.nix
    ./lualine.nix
    ./mini.nix
    ./neo-tree.nix
    ./neogen.nix
    ./neogit.nix
    # ./neotest.nix
    ./noice.nix
    # ./nvim-autopairs.nix
    ./nvim-ufo.nix
    ./oil.nix
    ./sleuth.nix
    # ./telescope.nix
    ./tmux-navigator.nix
    ./todo-comments.nix
    ./treesitter-refactor.nix
    ./treesitter.nix
    ./undotree.nix
    ./wakatime.nix
    ./which-key.nix
  ];
}

