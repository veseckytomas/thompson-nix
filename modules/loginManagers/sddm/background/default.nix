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
{pkgs, ...}: let
  sourceFiles = ./sddm_bg.png;
in
  pkgs.stdenv.mkDerivation {
    name = "sddm-background";
    src = pkgs.lib.fileset.toSource {
      root = ./.;
      fileset = sourceFiles;
    };
    postInstall = ''
      mkdir -p $out
      cp ${sourceFiles} $out/sddm_bg.png
    '';
  }
