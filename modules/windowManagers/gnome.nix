{ config, pkgs, ... }:

{
  services.xserver = {
    desktopManager.gnome.enable = true;
  };
  environment.gnome.excludePackages = (with pkgs; [
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
  ]) ++ (with pkgs.gnome; [
    gnome-music
    gnome-characters
    gnome-contacts
    gnome-weather
    gnome-clocks
    gnome-maps
    gnome-software
  ]);
}
