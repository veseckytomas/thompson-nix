{ config, pkgs, ... }:

{
  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style = "adwaita-dark";
  # qt.style.name = "adwaita-dark";
  # qt.style.package = pkgs.adwaita-qt;
}
