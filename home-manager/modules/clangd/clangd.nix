{ config, pkgs, ... }:

{
  home.file.".config/clangd/config.yaml".source = ./config.yaml;
}
