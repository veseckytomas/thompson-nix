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
  config,
  pkgs,
  ...
}: let
  config_dir = ".config/rofi";
in {
  home.file."${config_dir}/bin/launcher".source = ./bin/launcher;
  home.file."${config_dir}/bin/powermenu".source = ./bin/powermenu;
  home.file."${config_dir}/bin/screenshot".source = ./bin/screenshot;
  home.file."${config_dir}/config/askpass.rasi".source = ./config/askpass.rasi;
  home.file."${config_dir}/config/colors.rasi".source = ./config/colors.rasi;
  home.file."${config_dir}/config/confirm.rasi".source = ./config/confirm.rasi;
  home.file."${config_dir}/config/font.rasi".source = ./config/font.rasi;
  home.file."${config_dir}/config/launcher.rasi".source = ./config/launcher.rasi;
  home.file."${config_dir}/config/powermenu.rasi".source = ./config/powermenu.rasi;
  home.file."${config_dir}/config/screenshot.rasi".source = ./config/screenshot.rasi;
  home.packages = with pkgs; [
    rofi
  ];
}
