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
{inputs, ...}: {
  imports = [
    ./audio
    ./bootLoaders
    ./common
    ./loginManagers
    ./networking
    ./virtualisation
    ./windowManagers
    inputs.catppuccin.nixosModules.catppuccin
  ];

  catppuccin = {
    enable = false;
    autoEnable = false;
  };
}
