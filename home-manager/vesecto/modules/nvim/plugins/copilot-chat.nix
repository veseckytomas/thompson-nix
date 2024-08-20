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
    plugins.copilot-chat = {
      enable = true;
    };
    keymaps = [
      {
        mode = [ "n" ];
        key = "<leader>cc";
        action = "<cmd>CopilotChat<CR>";
        options.desc = "[C]opilot [C]hat";
      }
    ];
  };
}

