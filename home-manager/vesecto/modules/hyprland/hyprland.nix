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
  config_dir = ".config/hypr";
in {
  home.file."${config_dir}/catppuccin.conf".source = ./catppuccin.conf;
  wayland.windowManager.hyprland = {
    settings = {
      catppuccin = {
        enable = true;
        accent = "mauve";
        flavor = "mocha";
      };
      # autostart
      exec-once = [
        "nm-applet &"
        "hyprlock"
        "exec-once=waybar &"
        "swaync &"
        "hyprpaper &"
        "hypridle"
      ];

      input = {
        kb_layout = "us,cs";
        numlock_by_default = true;
        touchpad = {
          natural_scroll = true;
        };
      };

      general = {
        "$mainMod" = "SUPER";
      };
    };
  };
}
