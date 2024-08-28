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
  programs.nixvim.plugins.which-key = {
    enable = true;
    settings = {
      spec = [
        {
          __unkeyed-1 = "<leader>c";
          desc = "[C]ode";
        }
        {
          __unkeyed-1 = "<leader>d";
          desc = "[D]ebug";
        }
        {
          __unkeyed-1 = "<leader>r";
          desc = "[R]ename";
        }
        {
          __unkeyed-1 = "<leader>s";
          desc = "[S]earch";
        }
        {
          __unkeyed-1 = "<leader>t";
          desc = "[T]oggle";
        }
        {
          __unkeyed-1 = "<leader>g";
          desc = "[G]it";
        }
      ];
    };
  };
}
