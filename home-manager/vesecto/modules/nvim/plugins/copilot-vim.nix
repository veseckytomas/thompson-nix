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
    plugins.copilot-vim = {
      enable = true;
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>cg";
        action = "<cmd>Copilot<CR>";
        options.desc = "[C]opilot [G]enerate";
      }
    ];
  };
}
