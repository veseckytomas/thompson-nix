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
  config_dir = ".config/qtile";
in {
  home.file = {
    "${config_dir}/config.py".source = ./config.py;
    "${config_dir}/colors.py".source = ./colors.py;
    "${config_dir}/autostart.sh".source = ./autostart.sh;
    "${config_dir}/images/arch.png".source = ./images/arch.png;
    "${config_dir}/images/arch_background.jpg".source = ./images/arch_background.jpg;
    "${config_dir}/images/linux.png".source = ./images/linux.png;
    "${config_dir}/images/linux_background.jpg".source = ./images/linux_background.jpg;
    "${config_dir}/images/nixos.png".source = ./images/nixos.png;
    "${config_dir}/images/nixos_background.png".source = ./images/nixos_background.png;
  };
}
