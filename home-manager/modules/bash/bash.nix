{ config, pkgs, lib, ... }:

{
  programs.bash.enable = true;
  home.file.".bashrc".source = ./bashrc;
}
