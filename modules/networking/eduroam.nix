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
  pkgs,
  username,
  ...
}: let
  # CTU login, not the system user.
  ctuLogin = "vesecto1";

  # NMSettingSecretFlags: secret lives in gnome-keyring, never in this repo.
  agentOwned = "1";
in {
  networking.networkmanager.ensureProfiles.profiles = {
    eduroam = {
      connection = {
        id = "eduroam";
        type = "wifi";
        # UUID reused so the existing gnome-keyring secret still resolves.
        uuid = "95e91d1b-15a7-4466-89af-1b67c6d4269c";
        autoconnect = true;
        permissions = "user:${username}:;";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "eduroam";
      };
      wifi-security.key-mgmt = "wpa-eap";
      "802-1x" = {
        eap = "peap;";
        phase2-auth = "mschapv2";
        identity = "${ctuLogin}@cvut.cz";
        # Pinned: RADIUS sends a cross-signed Sectigo R46 that no bundle can chain, so only this root resolves.
        ca-cert = "${pkgs.cacert.unbundled}/etc/ssl/certs/USERTrust_RSA_Certification_Authority:1fd6d30fca3ca51a81bbc640e35032d.crt";
        domain-suffix-match = "radius.cvut.cz";
        password-flags = agentOwned;
      };
      ipv4.method = "auto";
      ipv6 = {
        method = "auto";
        addr-gen-mode = "default";
      };
    };
  };
}
