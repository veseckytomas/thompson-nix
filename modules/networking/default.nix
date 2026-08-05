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
    ./omniroute-proxy.nix
  ];

  # Enable networking
  networking.networkmanager = {
    enable = true;
    plugins = [
      pkgs.networkmanager-openvpn
      pkgs.networkmanager-openconnect
    ];
  };
  programs.nm-applet.enable = true;

  networking.firewall = {
    allowedTCPPorts = [53317];
    allowedUDPPorts = [53317];
  };
  environment = {
    # Packages
    systemPackages = with pkgs; [
      networkmanagerapplet
    ];
    # VPN config
    etc = {
      "NetworkManager/system-connections/cvut-vpn.nmconnection" = {
        source = ./cvut-vpn.nmconnection;
        mode = "0600";
      };
      "NetworkManager/system-connections/vic-vpn.nmconnection" = {
        source = ./vic-vpn.nmconnection;
        mode = "0600";
      };
      # "NetworkManager/system-connections/fit-vpn.nmconnection" = {
      #   source = ./fit-vpn.nmconnection;
      #   mode = "0600";
      # };
    };
  };
}
