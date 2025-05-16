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
  # Set keymaps
  programs.nixvim.keymaps = [
    # Set move between windows
    {
      mode = ["n"];
      key = "<C-h>";
      action = "<C-w><C-h>";
      options.desc = "Move focus to the left window";
    }
    {
      mode = ["n"];
      key = "<C-l>";
      action = "<C-w><C-l>";
      options.desc = "Move focus to the right window";
    }
    {
      mode = ["n"];
      key = "<C-j>";
      action = "<C-w><C-j>";
      options.desc = "Move focus to the lower window";
    }
    {
      mode = ["n"];
      key = "<C-k>";
      action = "<C-w><C-k>";
      options.desc = "Move focus to the upper window";
    }

    # Set open split keymaps
    {
      mode = ["n"];
      key = "<leader>vs";
      action = "<cmd>vsplit<CR>";
      options.desc = "[V]ertical [S]plit";
    }
    {
      mode = ["n"];
      key = "<leader>hs";
      action = "<cmd>split<CR>";
      options.desc = "[H]orizontal [S]plit";
    }

    # Set terminal keymap
    {
      mode = ["n"];
      key = "<leader>tt";
      action = "<cmd>terminal<CR>";
      options.desc = "Open Terminal";
    }

    # Set buffer keymaps
    {
      mode = ["n"];
      key = "<leader>bc";
      action = "<cmd>bd<CR>";
      options.desc = "[B]buffer [C]lose";
    }
    {
      mode = ["n"];
      key = "<leader>bn";
      action = "<cmd>bn<CR>";
      options.desc = "[B]buffer [N]ext";
    }
    {
      mode = ["n"];
      key = "<leader>bp";
      action = "<cmd>bp<CR>";
      options.desc = "[B]buffer [P]revious";
    }
    {
      mode = ["n"];
      key = "<C-p>";
      action = "<cmd>bn<CR>";
      options.desc = "[B]buffer [N]ext";
    }
    {
      mode = ["n"];
      key = "<C-o>";
      action = "<cmd>bp<CR>";
      options.desc = "[B]buffer [P]revious";
    }

    # Clear search on escape
    {
      mode = ["n"];
      key = "<Esc>";
      action = "<cmd>nohlsearch<CR>";
      options.desc = "Clear search";
    }

    # Open evince
    {
      mode = ["n"];
      key = "<leader>ev";
      action = "<cmd>!evince &<CR>";
      options.desc = "Open Evince";
    }

    # Run tex
    {
      mode = ["n"];
      key = "<leader>tr";
      action = "<cmd>!lualatex main.tex<CR>";
      options.desc = "Open Evince";
    }
  ];
}
