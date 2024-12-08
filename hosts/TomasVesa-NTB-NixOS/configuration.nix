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
  boot.initrd.luks.devices."luks-93144126-933d-426a-9237-5f8eba7c9158".device = "/dev/disk/by-uuid/93144126-933d-426a-9237-5f8eba7c9158";
  networking.hostName = "TomasVesa-NTB-NixOS";

  # System version
  system.stateVersion = "24.05";
}
