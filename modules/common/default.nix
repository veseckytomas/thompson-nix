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
{...}: {
  imports = [
    ./autorandr.nix
    ./backups.nix
    ./common.nix
    ./flatpaks.nix
    # ./gaming.nix
    ./journald.nix
    ./kanata.nix
    ./locale.nix
    ./nix-build-limits.nix
    # ./notebook.nix
    ./packages
    ./security.nix
    ./users.nix
  ];
}
