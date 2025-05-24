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
{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
  ];
  networking.hostName = "Reyhan";

  environment.systemPackages = with pkgs; [
    docker-compose
  ];
  virtualisation.docker = {
    enable = true;
    package = pkgs.docker;
  };
  networking.firewall.allowedTCPPorts = [5432];

  # System version
  system.stateVersion = "24.05";
}
