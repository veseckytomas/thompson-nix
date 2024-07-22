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

{ pkgs }:

let
  imgLink = "https://gitlab.com/vesecky.tomas/thompson-nix/-/raw/master/modules/loginManagers/sddm-theme/sddm_bg.png?inline=false";
  configLink = "https://gitlab.com/vesecky.tomas/thompson-nix/-/raw/master/modules/loginManagers/sddm-theme/sddm-config.conf?inline=false";

  img = pkgs.fetchurl {
    url = imgLink;
    sha256 = "sha256-RdrkvsVB6fHnyDZQ6wCGc7lUP7FoDYGvx2jfWB1WSvI=";
  };
  config = pkgs.fetchurl {
    url = configLink;
    sha256 = "0q0hb5cq0fx88sgcvyw8nj1rc6z5bd6dxnqmxvrxq8970fsx9zyi";

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
