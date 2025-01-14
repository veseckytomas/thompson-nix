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
  pkgs,
  inputs,
  ...
}: {
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "render-markdown.nvim";
        src = inputs.render-markdown-nvim;
      })
    ];
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>mr";
        action = "<cmd>RenderMarkdown toggle<CR>";
        options.desc = "[M]arkdown [R]ender";
      }
    ];
  };
}
