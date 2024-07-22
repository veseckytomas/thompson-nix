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

{ config, pkgs, ... }:

{
  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Enable networking
  networking.networkmanager.enable = false;
  programs.nm-applet.enable = true;

  # Enable Yubikey support
  security.pam.u2f = {
    enable = true;
    settings.cue = true;
    control = "required";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Set your time zone
  time.timeZone = "Europe/Prague";

  system.stateVersion = "24.05";
}
