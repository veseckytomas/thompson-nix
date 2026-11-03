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
  programs.ncspot = {
    enable = true;
    settings = {
      use_nerdfont = true;
      theme = {
        # Catppuccin Mocha mauve theme
        background = "#1e1e2e";
        primary = "#cdd6f4";
        secondary = "#94e2d5";
        title = "#cba6f7";
        playing = "#a6e3a1";
        playing_bg = "#1e1e2e";
        highlight = "#cdd6f4";
        highlight_bg = "#746292";
        playing_selected = "#a6e3a1";
        error = "#1e1e2e";
        error_bg = "#f38ba8";
        statusbar = "#cba6f7";
        statusbar_bg = "#313244";
        statusbar_progress = "#cba6f7";
        cmdline = "#cba6f7";
        cmdline_bg = "#181825";
      };
    };
  };
}
