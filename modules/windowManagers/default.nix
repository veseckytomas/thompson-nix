#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    # ./awesome.nix
    # ./cinnamon.nix
    # ./deepin.nix
    # ./enlightenment.nix
    # ./gnome.nix
    ./hyprland.nix
    # ./i3.nix
    # ./plasma.nix
    ./qtile.nix
    # ./xfce.nix
    # ./xmonad.nix
  ];
  # environment.sessionVariables.NIX_GSETTINGS_OVERRIDES_DIR = let
  #   cfg = config.services.xserver.desktopManager.gnome;
  #   nixos-background-light = pkgs.nixos-artwork.wallpapers.simple-blue;
  #   nixos-background-dark = pkgs.nixos-artwork.wallpapers.simple-dark-gray;
  #   flashbackEnabled = cfg.flashback.enableMetacity || lib.length cfg.flashback.customSessions > 0;
  #   nixos-gsettings-desktop-schemas = pkgs.gnome.nixos-gsettings-overrides.override {
  #     inherit (cfg) extraGSettingsOverrides extraGSettingsOverridePackages favoriteAppsOverride;
  #     inherit flashbackEnabled nixos-background-dark nixos-background-light;
  #   };
  # in
  #   lib.mkForce (pkgs.glib.getSchemaPath nixos-gsettings-desktop-schemas);
  # services.displayManager.defaultSession = lib.mkForce null;
  # programs.ssh.askPassword = lib.mkForce "${pkgs.plasma5Packages.ksshaskpass.out}/bin/ksshaskpass";
}
