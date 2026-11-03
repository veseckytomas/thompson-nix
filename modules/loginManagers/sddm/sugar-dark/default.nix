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
  inputs,
  ...
}: let
  img = pkgs.fetchurl {
    url = "https://gitlab.com/vesecky.tomas/thompson-nix/-/raw/4496ae9e0f068094fa168df801b6f869bd0bece2/modules/loginManagers/sddm-theme/sddm_bg.png";
    sha256 = "1wjaaqfmipv8qypq23b8n4zm9fbkhq0fnl1nr3kz3sa1qnzf9nj5";
  };
  config = pkgs.fetchurl {
    url = "https://gitlab.com/vesecky.tomas/thompson-nix/-/raw/4496ae9e0f068094fa168df801b6f869bd0bece2/modules/loginManagers/sddm-theme/sddm-config.conf";
    sha256 = "1s0mw3rbif5kyhiz13c6z92mkxwc8jjahyxdfw8vzzfhhz0d4294";
  };
in
  pkgs.stdenv.mkDerivation {
    name = "sddm-theme";
    src = inputs.sddm-theme;
    installPhase = ''
      mkdir -p $out
      cp -R ./* $out/
      rm background.jpg
      cp -r ${img} $out/Background.jpg
      rm theme.conf
      cp -r ${config} $out/theme.conf
    '';
  }
