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
{pkgs, ...}: {
  services = {
    xserver = {
      desktopManager.gnome.enable = true;
    };
  };
  environment.gnome.excludePackages = with pkgs; [
    gnome-photos
    gnome-tour
    cheese
    gedit
    epiphany
    geary
    totem
    gnome-calendar
    gnome-calculator
    simple-scan
    yelp
    gnome-music
    tali
    iagno
    hitori
    atomix
    gnome-initial-setup
    gnome-characters
    gnome-contacts
    gnome-weather
    gnome-clocks
    gnome-maps
    gnome-software
  ];
  environment.systemPackages = with pkgs; [
    gnome-tweaks
  ];
}
