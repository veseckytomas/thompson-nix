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
  pkgs,
  lib,
  ...
}: {
  # Enable nix flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Set kernel
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

  services = {
    # Enable Gnome keyring
    gnome.gnome-keyring.enable = true;

    # Printing
    printing = {
      enable = true;
      drivers = [
        pkgs.hplipWithPlugin
      ];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };
    ipp-usb.enable = true;

    libinput.enable = true;
    fstrim.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;

    smartd = {
      enable = true;
      autodetect = true;
    };
  };

  # Set your time zone
  time.timeZone = "Europe/Prague";

  # Enable zsh completion for system packages
  environment.pathsToLink = ["/share/zsh"];
}
