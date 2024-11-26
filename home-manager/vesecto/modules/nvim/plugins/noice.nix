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
{...}: let
  pkgs-old = builtins.fetchGit {
    name = "nixpkgs-old";
    url = "https://github.com/NixOS/nixpkgs/";
    ref = "refs/heads/nixos-unstable";
    rev = "4aa36568d413aca0ea84a1684d2d46f55dbabad7";
  };
in {
  programs.nixvim = {
    plugins.noice = {
      enable = true;
      package = pkgs-old.noice;
      settings = {
        extraOptions = {
          lsp = {
            override = {
              "vim.lsp.util.convert_input_to_markdown_lines" = true;
              "vim.lsp.util.stylize_markdown" = true;
              "cmp.entry.get_documentation" = true;
            };
          };
        };
        presets = {
          bottom_search = true;
          command_palette = true;
          long_message_to_split = true;
          inc_rename = false;
          lsp_doc_border = false;
        };
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>nd";
        action = "<cmd>NoiceDismiss<CR>";
        options.desc = "[N]oice [D]ismiss";
      }
    ];
  };
}
