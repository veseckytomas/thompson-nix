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
  imgLink = "https://gitlab.com/vesecky.tomas/thompson-nix/-/raw/4496ae9e0f068094fa168df801b6f869bd0bece2/modules/loginManagers/sddm-theme/sddm_bg.png";
  configLink = "https://gitlab.com/vesecky.tomas/thompson-nix/-/raw/4496ae9e0f068094fa168df801b6f869bd0bece2/modules/loginManagers/sddm-theme/sddm-config.conf";

  img = pkgs.fetchurl {
    url = imgLink;
    sha256 = "1wjaaqfmipv8qypq23b8n4zm9fbkhq0fnl1nr3kz3sa1qnzf9nj5";
  };
  config = pkgs.fetchurl {
    url = configLink;
    sha256 = "1s0mw3rbif5kyhiz13c6z92mkxwc8jjahyxdfw8vzzfhhz0d4294";
  };
in
  pkgs.stdenv.mkDerivation {
    name = "sddm-theme";
    src = pkgs.fetchFromGitHub {
      owner = "MarianArlt";
      repo = "sddm-sugar-dark";
      rev = "ceb2c455663429be03ba62d9f898c571650ef7fe";
      sha256 = "0153z1kylbhc9d12nxy9vpn0spxgrhgy36wy37pk6ysq7akaqlvy";
    };
    installPhase = ''
      mkdir -p $out
      cp -R ./* $out/
      rm Background.jpg
      cp -r ${img} $out/Background.jpg
      rm theme.conf
      cp -r ${config} $out/theme.conf
    '';
  }
