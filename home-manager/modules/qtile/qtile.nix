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

let
  config_dir = ".config/qtile";
in 
{
  home.file."${config_dir}/config.py".source = ./config.py;
  home.file."${config_dir}/colors.py".source = ./colors.py;
  home.file."${config_dir}/autostart.sh".source = ./autostart.sh;
  home.file."${config_dir}/images/arch.png".source = ./images/arch.png;
  home.file."${config_dir}/images/arch_background.jpg".source = ./images/arch_background.jpg;
  home.file."${config_dir}/images/linux.png".source = ./images/linux.png;
  home.file."${config_dir}/images/linux_background.jpg".source = ./images/linux_background.jpg;
  home.file."${config_dir}/images/nixos.png".source = ./images/nixos.png;
  home.file."${config_dir}/images/nixos_background.png".source = ./images/nixos_background.png;
}
