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
  programs.nixvim = {
    plugins.tmux-navigator = {
      enable = true;
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<C-h>";
        action = "<cmd>TmuxNavigateLeft<CR>";
        options.desc = "Window left";
      }
      {
        mode = ["n"];
        key = "<C-j>";
        action = "<cmd>TmuxNavigateDown<CR>";
        options.desc = "Window down";
      }
      {
        mode = ["n"];
        key = "<C-k>";
        action = "<cmd>TmuxNavigateUp<CR>";
        options.desc = "Window up";
      }
      {
        mode = ["n"];
        key = "<C-l>";
        action = "<cmd>TmuxNavigateRight<CR>";
        options.desc = "Window right";
      }
    ];
  };
}
