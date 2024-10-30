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
  config_dir = ".config/backgrounds";
in {
  home.file = {
    "${config_dir}/arch.png".source = ./arch.png;
    "${config_dir}/arch_background.jpg".source = ./arch_background.jpg;
    "${config_dir}/linux.png".source = ./linux.png;
    "${config_dir}/linux_background.jpg".source = ./linux_background.jpg;
    "${config_dir}/nixos.png".source = ./nixos.png;
    "${config_dir}/nixos_background.png".source = ./nixos_background.png;
  };
}
