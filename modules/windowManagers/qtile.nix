{ config, pkgs, ... }:

{
  services.libinput.touchpad.naturalScrolling = true;
  services.acpid.enable = true;
  services.xserver = {
    windowManager.qtile = {
      enable = true;
      extraPackages = python3Packages: with python3Packages; [
        qtile-extras
      ];
    };
  };
  environment.systemPackages = with pkgs; [
    feh
    rofi
    i3lock
    picom
  ];
}
