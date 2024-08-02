#________
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
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.85;
      font = {
        size = 10.0;
        bold = {
          family = "Hack Nerd Font Mono";
          style = "Bold";
        };
        bold_italic = {
          family = "Hack Nerd Font Mono";
          style = "Bold Italic";
        };
        italic = {
          family = "Hack Nerd Font Mono";
          style = "Italic";
        };
        normal = {
          family = "Hack Nerd Font Mono";
          style = "Regular";
        };
      };
      colors = {
        primary = {
          background = "#1e1e1e";
          foreground = "#ffffff";
        };
        normal = {
          black = "#171421";
          red = "#c01c28";
          green = "#26a269";
          yellow = "#a2734c";
          blue = "#12488b";
          magenta = "#a347ba";
          cyan = "#2aa1b3";
          white = "#d0cfcc";
        };
        bright = {
          black = "#5e5c64";
          red = "#f66151";
          green = "#33d17a";
          yellow = "#e9ad0c";
          blue = "#2a7bde";
          magenta = "#c061cb";
          cyan = "#33c7de";
          white = "#ffffff";
        };
      };
    };
  };
}
