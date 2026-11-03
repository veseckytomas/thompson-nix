#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{pkgs, ...}: let
  config_dir = ".config/i3lock";
in {
  home = {
    file = {
      "${config_dir}/arch_lock_screen.png".source = ./arch_lock_screen.png;
      "${config_dir}/linux_lock_screen.png".source = ./linux_lock_screen.png;
      "${config_dir}/nixos_lock_screen.png".source = ./nixos_lock_screen.png;
      "${config_dir}/lock.sh".source = ./lock.sh;
    };
    packages = with pkgs; [
      i3lock
    ];
  };
}
