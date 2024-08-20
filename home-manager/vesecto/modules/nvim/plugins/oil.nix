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

{ config, pkgs, ... }:

{
  programs.nixvim = {
    plugins.oil = {
      enable = true;
      settings = {
        columns = [
          "icon"
        ];
        view_options = {
          show_hidden = true;
          is_always_hidden = ''
            function(name, _)
              return name == ".git"
            end
          '';
        };
        float = {
          padding = 2;
          max_width = 90;
          max_height = 0;
        };
        win_options = {
          wrap = true;
          winblend = 0;
        };
        keymaps = {
          "<C-c>" = false;
          "q" = "actions.close";
          "M-h" = "actions.select.split";
          "<C-h>" = false;
          "<C-j>" = false;
          "<C-k>" = false;
          "<C-l>" = false;
        };
      };
    };
    keymaps = [
      {
        mode = [ "n" ];
        key = "<leader>od";
        action = "<cmd>Oil<CR>";
        options.desc = "[O]pen [D]irectory";
      }
    ];
    extraConfigLua = ''
      vim.keymap.set("n", "<leader>of", require("oil").toggle_float, { desc = "[O]pen directory [F]loating" })
    '';
  };
}

