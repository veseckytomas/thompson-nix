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
    ./alpha.nix
    ./ccc.nix
    ./cmp.nix
    ./cmp-buffer.nix
    # ./cmp-cmdline.nix
    ./cmp-nvim-lsp.nix
    ./cmp-path.nix
    ./chatgpt/chatgpt.nix
    ./codeium-nvim.nix
    ./codesnap.nix
    ./comment.nix
    ./conform-nvim.nix
    ./copilot-chat.nix
    ./copilot-cmp.nix
    ./copilot-lua.nix
    # ./copilot-vim.nix
    ./dap.nix
    ./diffview.nix
    ./fidget.nix
    ./friendly-snippets.nix
    ./gitsigns.nix
    # ./indent-blankline.nix
    ./lint.nix
    ./lsp.nix
    ./lspkind.nix
    ./lualine.nix
    ./luasnip.nix
    ./mini.nix
    ./multicursors.nix
    ./neo-tree.nix
    ./neogen.nix
    ./neogit.nix
    # ./neotest.nix
    ./nix.nix
    ./noice.nix
    # ./nvim-autopairs.nix
    ./nvim-ufo.nix
    ./oil.nix
    ./sleuth.nix
    ./telescope.nix
    ./tmux-navigator.nix
    ./todo-comments.nix
    ./treesitter-refactor.nix
    ./treesitter.nix
    ./ts-autotag.nix
    ./undotree.nix
    ./wakatime.nix
    ./which-key.nix
  ];
}
