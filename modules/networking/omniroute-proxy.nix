#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
# Pairs with the HM omniroute plugin: Caddy can't live in HM (port 80 needs root).
{...}: {
  networking.extraHosts = ''
    127.0.0.1 omniroute
  '';

  services.caddy = {
    enable = true;
    virtualHosts."http://omniroute".extraConfig = ''
      bind 127.0.0.1
      reverse_proxy 127.0.0.1:20128
    '';
  };
}
