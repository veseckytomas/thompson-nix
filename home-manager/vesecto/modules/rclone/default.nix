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
  config_dir = ".config/rclone";
in {
  home = {
    file = {
      "${config_dir}/upload.sh".source = ./upload.sh;
      "${config_dir}/download.sh".source = ./download.sh;
    };
    packages = with pkgs; [
      rclone
    ];
  };
}
