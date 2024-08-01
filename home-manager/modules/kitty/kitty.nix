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
  config_dir = ".config/kitty";
in 
{
  home.file."${config_dir}/kitty.conf".source = ./kitty.conf;
  home.file."${config_dir}/Catppuccin-Mocha.conf".source = ./Catppuccin-Mocha.conf;
}
