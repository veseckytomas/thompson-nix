{ config, pkgs, ... }:

{
  services.libinput.touchpad.naturalScrolling = true;
  services.xserver = {
    enable = true;
    displayManager.sddm.enable = true;
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
  ];
}
