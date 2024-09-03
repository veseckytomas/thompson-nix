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
    plugins.ccc = {
      enable = true;
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>ccp";
        action = "<cmd>CccPick<CR>";
        options.desc = "[C][C]C [P]ick";
      }
      {
        mode = ["n"];
        key = "<leader>ccc";
        action = "<cmd>CccConvert<CR>";
        options.desc = "[C][C]C [C]onvert";
      }
    ];
  };
}
