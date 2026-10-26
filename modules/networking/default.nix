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
    ./eduroam.nix
    ./fortivpn.nix
    ./networkmanager-recover.nix
    ./omniroute-connectivity.nix
    ./omniroute-proxy.nix
    ./vpn.nix
  ];

  # Enable networking
  networking.networkmanager = {
    enable = true;
    plugins = [
      pkgs.networkmanager-openvpn
      pkgs.networkmanager-openconnect
    ];
    # resolved keeps the DHCP/VPN servers per-link, so *.cvut.cz still resolves through the tunnel.
    dns = "systemd-resolved";
  };

  # Caches lookups across a link flap, so a brief drop no longer bursts into ENOTFOUND failures.
  services.resolved.enable = true;
  programs.nm-applet.enable = true;

  networking.firewall = {
    allowedTCPPorts = [53317];
    allowedUDPPorts = [53317];
  };
  environment.systemPackages = [pkgs.networkmanagerapplet];
}
