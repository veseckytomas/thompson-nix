{ config, pkgs, ... }:
{
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
    # timeout = null;
    timeout = 0;
  };
}
