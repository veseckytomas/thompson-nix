{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  networking.hostName = "TomasVesa-NTB2-NixOS"; # Define your hostname.
}
