{ config, pkgs, ... }:

{
  services.xserver = {
    desktopManager.gnome.enable = true;
  };
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    cheese
    gnome-terminal
    gedit
    epiphany
    geary
    totem
  ]) ++ (with pkgs.gnome; [
    gnome-music
    gnome-characters
    tali
    iagno
    hitori
    atomix
  ]);
}
