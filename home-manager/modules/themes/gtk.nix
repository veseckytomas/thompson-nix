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

{ config, pkgs, ... }:

let
  gruvboxplus = import ./gruvbox-plus.nix { inherit pkgs; };
in 
{
  gtk = {
    enable = true;

    # cursorTheme = {
    #   package = pkgs.bibata-cursors;
    #   name = "Bibata-Modern-Ice";
    # };

    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3";
    };

    iconTheme = {
      package = gruvboxplus;
      name = "GruvboxPlus";
    };
  };
}
