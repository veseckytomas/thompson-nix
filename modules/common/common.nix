{ config, pkgs, ... }:

{
  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Enable networking
  networking.networkmanager.enable = false;

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
