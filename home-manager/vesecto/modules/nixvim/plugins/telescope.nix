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
    plugins.telescope = {
      enable = true;
      highlightTheme = "Catppuccin-Mocha";
      extensions = {
        ui-select.enable = true;
        fzf-native.enable = true;
        undo.enable = true;
      };
      settings = {
        defaults = {
          file_ignore_patterns = [
            ".git/"
            ".mypy_cache/"
            "node_modules/"
            "__pycache__/"
            "output/"
            "data/"
            "%.ipynb"
            "secrets/"
          ];
        };
        pickers = {
          find_files = {
            find_command = [
              "rg"
              "--files"
              "--hidden"
            ];
          };
        };
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>fn";
        action = "<cmd>Telescope noice<CR>";
        options.desc = "[F]ind [N]oice";
      }
      {
        mode = ["n"];
        key = "<leader>fm";
        action = "<cmd>Telescope notify<CR>";
        options.desc = "[F]ind Notifications";
      }
      {
        mode = ["n"];
        key = "<leader>ff";
        action.__raw = ''
          require("telescope.builtin").find_files
        '';
        options.desc = "[F]ind [F]iles";
      }
      {
        mode = ["n"];
        key = "<leader>fb";
        action.__raw = ''
          require("telescope.builtin").buffers
        '';
        options.desc = "[F]earch [B]buffers";
      }
      {
        mode = ["n"];
        key = "<leader>fg";
        action.__raw = ''
          require("telescope.builtin").live_grep
        '';
        options.desc = "[F]ind by [G]rep";
      }
      {
        mode = ["n"];
        key = "<leader>fh";
        action.__raw = ''
          require("telescope.builtin").help_tags
        '';
        options.desc = "[F]ind [H]elp";
      }
      {
        mode = ["n"];
        key = "<leader>fk";
        action.__raw = ''
          require("telescope.builtin").keymaps
        '';
        options.desc = "[F]ind [K]eymaps";
      }
      {
        mode = ["n"];
        key = "<leader>fs";
        action.__raw = ''
          require("telescope.builtin").builtin
        '';
        options.desc = "[F]ind [S]elect Telescope";
      }
      {
        mode = ["n"];
        key = "<leader>fw";
        action.__raw = ''
          require("telescope.builtin").grep_string
        '';
        options.desc = "[F]ind current [W]ord";
      }
    ];
  };
}
