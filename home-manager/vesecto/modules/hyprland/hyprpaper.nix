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
  services.hyprpaper = {
    enable = true;

    settings = {
      preload = [
        "${config.home.homeDirectory}/.config/backgrounds/nixos_background.png"
      ];
      wallpaper = [
        ", ${config.home.homeDirectory}/.config/backgrounds/nixos_background.png"
      ];
    };
  };
}
