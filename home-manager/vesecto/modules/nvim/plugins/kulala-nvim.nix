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
{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "kulala";
        src = pkgs.fetchFromGitHub {
          owner = "mistweaverco";
          repo = "kulala.nvim";
          rev = "7649576ca459146658b4c415d1a320bbedc3f564";
          hash = "sha256-lsct1/VGj0rtX3xzoSKQD7Rji7zsNrWSsHyZr1fdU44=";
        };
      })
    ];
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>o";
        action = "<cmd>Outline<cr>";
        options.desc = "[O]utline";
      }
    ];
    extraConfigLua = ''
    '';
  };
}
