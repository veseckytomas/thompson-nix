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
    plugins.gitsigns = {
      enable = true;
      settings = {
        current_line_blame = true;
        signs = {
          add.text = "+";
          change.text = "~";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
          untracked.text = "┆";
        };
        signs_staged = {
          add.text = "+";
          change.text = "~";
          delete.text = "_";
          topdelete.text = "‾";
          changedelete.text = "~";
          untracked.text = "┆";
        };
      };
      lazyLoad = {
        enable = true;
        settings = {
          keys = [
            "<leader>gp"
            "<leader>gg"
            "<leader>gr"
            "<leader>gs"
          ];
          cmd = [
            "GitSigns"
          ];
        };
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>gp";
        action = "<cmd>Gitsigns preview_hunk<CR>";
        options.desc = "[G]it [P]review hunk";
      }
      {
        mode = ["n"];
        key = "<leader>gg";
        action = "<cmd>Gitsigns<CR>";
        options.desc = "[G]itsigns";
      }
      {
        mode = ["n"];
        key = "<leader>gr";
        action = "<cmd>Gitsigns restore_hunk<CR>";
        options.desc = "[G]it [R]estore hunk";
      }
      {
        mode = ["n"];
        key = "<leader>gs";
        action = "<cmd>Gitsigns stage_hunk<CR>";
        options.desc = "[G]it [S]stage hunk";
      }
    ];
  };
}
