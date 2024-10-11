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
{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  name = "2048";
  src = pkgs.fetchFromGitHub {
    owner = "mevdschee";
    repo = "2048.c";
    rev = "c4f03846a47df967b967ca5f7d11fb4ef82196f4";
    sha256 = "";
  };
  installPhase = ''
    mkdir -p $out
    gcc -o 2048 2048.c
    cp -R ./2048 $out/
  '';
}
