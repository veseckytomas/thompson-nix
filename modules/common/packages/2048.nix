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
{
  pkgs,
  inputs,
  ...
}:
pkgs.stdenv.mkDerivation {
  name = "2048";
  src = inputs.game-2048;
  buildInputs = with pkgs; [gcc];
  buildPhase = ''
    gcc -o 2048 2048.c
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp -R ./2048 $out/bin
  '';
}
