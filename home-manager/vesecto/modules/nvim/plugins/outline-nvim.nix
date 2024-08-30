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
{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = [
      pkgs.vimPlugins.outline-nvim
    ];
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>o";
        action = "<cmd>lua require('outline').toggle()<cr>";
        options.desc = "[O]utline";
      }
    ];
    # extraConfigLua = ''
    #   require("outline").setup({})
    # '';
  };
}
