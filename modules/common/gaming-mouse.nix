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
  inputs,
  pkgs,
  ...
}: {
  # ratbagd and piper are pinned to flake inputs for newer device support than nixpkgs ships.
  services.ratbagd = {
    enable = true;
    package = pkgs.libratbag.overrideAttrs (old: {
      src = inputs.ratbagd;
    });
  };

  environment.systemPackages = with pkgs; [
    (piper.overrideAttrs
      (old: {
        src = inputs.piper;
      }))
  ];
}
