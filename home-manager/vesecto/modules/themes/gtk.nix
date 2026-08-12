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
  config,
  inputs,
  ...
}: let
  dracula-gtk-theme = pkgs.runCommandLocal "dracula-gtk-theme" {} ''
    mkdir -p $out/share/themes/Dracula
    cp -a ${inputs.dracula-gtk}/{gtk-2.0,gtk-3.0,gtk-3.20,gtk-4.0,assets,index.theme,metacity-1,gnome-shell} $out/share/themes/Dracula/
  '';
in {
  gtk = {
    enable = true;
    # Drives dconf's org.gnome.desktop.interface color-scheme, which xdg-desktop-portal-gtk exports as org.freedesktop.appearance for portal-aware apps.
    colorScheme = "dark";
    iconTheme = {
      name = "Dracula";
      package = pkgs.dracula-icon-theme;
    };
    theme = {
      package = dracula-gtk-theme;
      name = "Dracula";
    };
    gtk4.theme = config.gtk.theme;
  };
}
