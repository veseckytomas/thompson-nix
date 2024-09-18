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
    ./hardware-configuration.nix
  ];
  boot.initrd.luks.devices."luks-539c0859-dfb0-4823-8333-066792c99c43".device = "/dev/disk/by-uuid/539c0859-dfb0-4823-8333-066792c99c43";
  networking.hostName = "TomasVesa-PC-NixOS";
}
