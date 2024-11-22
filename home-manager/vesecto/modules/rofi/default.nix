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
{pkgs, ...}: let
  config_dir = ".config/rofi";
in {
  home = {
    file = {
      "${config_dir}/bin/launcher".source = ./bin/launcher;
      "${config_dir}/bin/powermenu".source = ./bin/powermenu;
      "${config_dir}/bin/screenshot".source = ./bin/screenshot;
      "${config_dir}/config/colors.rasi".source = ./config/colors.rasi;
      "${config_dir}/config/font.rasi".source = ./config/font.rasi;
      "${config_dir}/config/launcher.rasi".source = ./config/launcher.rasi;
      "${config_dir}/config/powermenu.rasi".source = ./config/powermenu.rasi;
      "${config_dir}/config/screenshot.rasi".source = ./config/screenshot.rasi;
    };
    packages = with pkgs; [
      rofi
    ];
  };
}
