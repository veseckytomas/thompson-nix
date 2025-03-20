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
  boot.initrd.luks.devices."luks-75e7b65c-68bb-4801-b9ec-49403d21ede5".device = "/dev/disk/by-uuid/75e7b65c-68bb-4801-b9ec-49403d21ede5";
  networking.hostName = "TomasVesa-NTB-NixOS";

  # Numberpad config
  services.asus-numberpad-driver = {
    enable = false;
    layout = "up5401ea";
    wayland = true;
    runtimeDir = "/run/user/1000/";
    waylandDisplay = "wayland-0";
    # config = {
    # };
  };
  # System version
  system.stateVersion = "24.11";
}
