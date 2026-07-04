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
{config, ...}: {
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        ignore_empty_input = true;
      };

      background = {
        monitor = "";
        color = "rgba(30, 30, 46, 1.0)";
        path = "${config.home.homeDirectory}/.config/backgrounds/nixos_background.png";
        blur_passes = 3;
      };

      animations = {
        enabled = false;
      };

      input-field = {
        monitor = "";
        size = "650, 100";
        position = "0, 0";
        halign = "center";
        valign = "center";

        inner_color = "rgba(30, 30, 46, 0.8)";
        outer_color = "rgba(205, 214, 244, 1.0)";
        outline_thickness = 4;

        font_family = "Hack Nerd Font Mono";
        font_color = "rgba(205, 214, 244, 1.0)";

        placeholder_text = "Enter Password";
        check_color = "rgba(203, 166, 247, 1.0)";
        fail_text = "<i>$FAIL ($ATTEMPTS)</i>";

        rounding = 0;
        shadow_passes = 0;
        fade_on_empty = false;
      };
    };
  };
}
