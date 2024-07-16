{ config, pkgs, ... }:

{
  qt.enable = true;
  qt.platformTheme = "gtk2";
  qt.style = "adwaita-dark";
}
