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
{pkgs, ...}: {
  services = {
    libinput.touchpad.naturalScrolling = true;
    acpid.enable = true;
    xserver = {
      windowManager.qtile = {
        enable = true;
        package = pkgs.python3Packages.qtile;
        extraPackages = _:
          with pkgs.python3Packages; [
            qtile-extras
          ];
      };
    };
    dunst = {
      enable = true;
      enableWayland = false;
      enableX11 = true;
    };
  };
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config = {
      common.default = ["gtk"];
      qtile.default = ["gtk"];
    };
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
