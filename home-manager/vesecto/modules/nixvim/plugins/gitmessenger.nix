#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{...}: {
  programs.nixvim = {
    plugins.gitmessenger = {
      enable = true;
      settings.date_format = "%Y-%m-%d %H:%M:%S";
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>gm";
        action = "<cmd>GitMessenger<CR>";
        options.desc = "[G]it [M]essenger";
      }
    ];
  };
}
