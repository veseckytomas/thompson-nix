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
  lib,
  pkgs,
  ...
}: {
  imports = [../../../../home-manager/vesecto/modules/opencode];

  home = {
    username = "vesecto";
    homeDirectory = "/home/vesecto";
    stateVersion = "26.05";
    # Desktop tools used by the shared opencode config's commands and skills.
    packages = [pkgs.glab pkgs.nix];
  };

  # --network=host gives opencode the existing host gateway; never provision a second one.
  opencodePlugins.omniroute.enable = lib.mkForce false;
}
