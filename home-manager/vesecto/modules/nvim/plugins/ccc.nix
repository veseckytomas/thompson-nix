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
    plugins.ccc = {
      enable = true;
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>cp";
        action = "<cmd>cccPick<CR>";
        options.desc = "[C]CC [P]ick";
      }
      {
        mode = ["n"];
        key = "<leader>cc";
        action = "<cmd>cccConvert<CR>";
        options.desc = "[C]CC [C]onvert";
      }
    ];
  };
}
