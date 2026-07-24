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
{...}: {
  imports = [
    ./autorandr.nix
    ./backups.nix
    ./common.nix
    ./flatpaks.nix
    # ./gaming.nix
    ./kanata.nix
    ./locale.nix
    # ./notebook.nix
    ./packages
    ./security.nix
    ./users.nix
  ];
}
