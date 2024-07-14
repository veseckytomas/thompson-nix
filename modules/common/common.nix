{ config, pkgs, ... }:

{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  # networking.wireless.enable = true;
  networking.networkmanager.enable = true;

  # security.sudo.wheelNeedsPassword = false;
  security.pam.u2f = {
    enable = true;
    settings.cue = true;
    control = "required";
  };

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  system.stateVersion = "24.05"; # Did you read the comment?
}
