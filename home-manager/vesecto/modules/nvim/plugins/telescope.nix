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
    ];
    extraConfigLua = ''
      vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files,   { desc = "[F]ind [F]iles" })
      vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers,      { desc = "[F]earch [B]uffers" })
      vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep,    { desc = "[F]ind by [G]rep" })
      vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags,    { desc = "[F]ind [H]elp" })
      vim.keymap.set("n", "<leader>fk", require("telescope.builtin").keymaps,      { desc = "[F]ind [K]eymaps" })
      vim.keymap.set("n", "<leader>fs", require("telescope.builtin").builtin,      { desc = "[F]ind [S]elect Telescope" })
      vim.keymap.set("n", "<leader>fw", require("telescope.builtin").grep_string,  { desc = "[F]ind current [W]ord" })
    '';
  };
}
