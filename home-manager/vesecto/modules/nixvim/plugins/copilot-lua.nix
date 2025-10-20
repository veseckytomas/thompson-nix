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
  inputs,
  pkgs,
  ...
}: {
  programs.nixvim.plugins.copilot-lua = {
    enable = true;
    # package = pkgs.vimPlugins.copilot-lua.overrideAttrs (old: {
    #   src = inputs.copilot-lua;
    # });
    settings = {
      filetypes = {
        text = false;
        markdown = false;
      };
      panel.enabled = false;
      suggestion.enabled = false;
    };
  };
}
