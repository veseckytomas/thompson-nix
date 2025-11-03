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
  inputs,
  pkgs,
  ...
}: let
  newBottles = pkgs.bottles.override {removeWarningPopup = true;};
in {
  # Enable polymc overlay
  nixpkgs.overlays = [inputs.polymc.overlay];

  # Load OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Enable steam
  programs = {
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      protontricks.enable = true;
    };
    gamemode.enable = true;
    gamescope = {
      enable = true;
      capSysNice = true;
      args = [
        "--rt"
        "--expose-wayland"
      ];
    };
  };

  # Other packages
  environment.systemPackages = with pkgs; [
    polymc
    mangohud
    protonup-ng
    lutris
    heroic
    newBottles
    libgpg-error
    libxml2
    freetype
    gnutls
    openldap
    SDL2
    sqlite
    xml2
  ];
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  environment.variables = {
    GPERF32_PATH = "${pkgs.pkgsi686Linux.gperftools}";
  };
}
