{ pkgs }:

let
  imgLink = "https://gitlab.com/vesecky.tomas/thompson-nix/-/blob/master/modules/loginManagers/sddm-theme/sddm_bg.png";

  img = pkgs.fetchurl {
    url = imgLink;
    sha256 = "19lc4k4y3xj26d52v1p3hql9nnimw846faabnrcss71k521vzxs7";
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
  '';
}
