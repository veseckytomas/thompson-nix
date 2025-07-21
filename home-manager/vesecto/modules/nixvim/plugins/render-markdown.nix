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
  programs.nixvim = {
    plugins.render-markdown = {
      enable = true;
      settings = {
        completions.lsp.enabled = true;
        file_types = ["markdown" "Avante"];
      };
      lazyLoad = {
        enable = true;
        settings = {
          cmd = "RenderMarkdown";
          keys = ["<leader>mr"];
          ft = ["Avante"];
        };
      };
    };
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
