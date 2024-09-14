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
          __unkeyed-1 = "<leader>b";
          desc = "[B]buffer";
        }

        # Conflict
        {
          __unkeyed-1 = "<leader>c";
          desc = "[C]ode";
        }
        {
          __unkeyed-1 = "<leader>c";
          desc = "ChatGPT/Copilot/CCC";
        }
        {
          __unkeyed-1 = "<leader>ch";
          desc = "[C][H]atGPT";
        }
        {
          __unkeyed-1 = "<leader>cc";
          desc = "[C][C]C";
        }
        {
          __unkeyed-1 = "<leader>co";
          desc = "[C][O]pilot";
        }

        # Conflict
        {
          __unkeyed-1 = "<leader>d";
          desc = "[D]atabase";
        }
        {
          __unkeyed-1 = "<leader>d";
          desc = "[D]ebug";
        }
        {
          __unkeyed-1 = "<leader>e";
          desc = "[E]vince";
        }
        {
          __unkeyed-1 = "<leader>f";
          desc = "[F]ind Telescope";
        }
        {
          __unkeyed-1 = "<leader>g";
          desc = "[G]it";
        }
        {
          __unkeyed-1 = "<leader>h";
          desc = "[H]orizontal";
        }
        {
          __unkeyed-1 = "<leader>l";
          desc = "[L]int";
        }
        {
          __unkeyed-1 = "<leader>m";
          desc = "[M]arkdown";
        }
        {
          __unkeyed-1 = "<leader>n";
          desc = "[N]oice";
        }
        {
          __unkeyed-1 = "<leader>o";
          desc = "[O]il";
        }
        {
          __unkeyed-1 = "<leader>s";
          desc = "[S]pectre";
        }
        {
          __unkeyed-1 = "<leader>t";
          desc = "[T]erminal";
        }
        {
          __unkeyed-1 = "<leader>u";
          desc = "[U]ndotree";
        }
        {
          __unkeyed-1 = "<leader>v";
          desc = "[V]ertical";
        }
        {
          __unkeyed-1 = "<leader>z";
          desc = "Fold";
        }
      ];
    };
  };
}
