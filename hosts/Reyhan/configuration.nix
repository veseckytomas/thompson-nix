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
{pkgs-stable, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];
  networking.hostName = "Reyhan";

  environment.systemPackages = with pkgs-stable; [
    docker-compose
  ];
  virtualisation.docker = {
    enable = true;
    package = pkgs-stable.docker;
  };
  networking.firewall.allowedTCPPorts = [5432];
}
