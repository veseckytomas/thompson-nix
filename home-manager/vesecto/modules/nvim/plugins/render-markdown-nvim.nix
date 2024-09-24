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
        name = "render-markdown.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "MeanderingProgrammer";
          repo = "render-markdown.nvim";
          rev = "0986638b381a4b01eb108bb946f3a67a9eb3d0ec";
          sha256 = "sha256-a2lwEiqDBOwqvFpV4yiH+EuvG1bwCTQJMe1tU5cQdg0=";
        };
      })
    ];
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>mr";
        action = "<cmd>RenderMarkdown toggle<CR>";
        options.desc = "[M]arkdown [R]ender";
      }
    ];
  };
}
