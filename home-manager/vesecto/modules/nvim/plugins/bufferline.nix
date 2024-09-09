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
  crust = "#181825";
in {
  programs.nixvim = {
    plugins.bufferline = {
      enable = true;
      settings = {
        highlights = {
          fill.bg = crust;
          separator.fg = crust;
          separator_visible.fg = crust;
          separator_selected.fg = crust;
        };
        options = {
          # hover = {
          #   enabled = true;
          #   delay = 200;
          #   reveal = ["close"];
          # };
          always_show_bufferline = true;
          diagnostics = "nvim_lsp";
          mode = "buffers";
          separator_style = "slant";
          diagnostics_indicator.__raw = ''
            function(count, level, diagnostics_dict, context)
              local icon = level:match("error") and " " or " "
              return " " .. icon .. count
            end
          '';
        };
      };
    };
  };
}
