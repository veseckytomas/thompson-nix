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
{
  pkgs,
  pkgs-stable,
  ...
}: {
  services = {
    libinput.touchpad.naturalScrolling = true;
    acpid.enable = true;
    xserver = {
      windowManager.qtile = {
        enable = true;
        package = pkgs-stable.python3Packages.qtile;
        extraPackages = python3Packages:
          with pkgs-stable.python3Packages; [
            qtile-extras
          ];
      };
    };
  };
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = ["gtk"];
  };
  environment.systemPackages = with pkgs; [
    feh
    rofi
    picom
    networkmanagerapplet
    flameshot
    autorandr
  ];
  imports = [
    ../common/i3lock.nix
  ];
}
