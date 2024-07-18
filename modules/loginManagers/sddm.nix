{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
  };
  services.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    theme = "${import ./sddm-theme/sddm-theme.nix { inherit pkgs; }}";
  };
  environment.systemPackages = with pkgs; [
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
  ];
}
