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
{
  username,
  pkgs,
  lib,
  ...
}: {
  boot.initrd.luks.devices."luks-75e7b65c-68bb-4801-b9ec-49403d21ede5".device = "/dev/disk/by-uuid/75e7b65c-68bb-4801-b9ec-49403d21ede5";

  # Numberpad config
  services.asus-numberpad-driver = {
    enable = true;
    layout = "up5401ea";
    wayland = false;
  };
  # boot.kernelPackages = pkgs.linuxPackages_6_16;
  users.users.${username}.extraGroups = ["input"];
  services.displayManager.sddm.autoNumlock = lib.mkForce false;

  # System version
  system.stateVersion = "24.11";
}
