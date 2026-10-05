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
{username, ...}: let
  # CTU login, not the system user.
  ctuLogin = "vesecto1";

  # CA is added manually post-install; see README.
  fitCa = "/home/${username}/.cert/nm-openvpn/fit-vpn-ca.pem";

  # NMSettingSecretFlags: secret lives in gnome-keyring, never in this repo.
  agentOwned = "1";

  # NMSettingSecretFlags: never stored, prompt on every connect.
  notSaved = "2";
in {
  networking.networkmanager.ensureProfiles.profiles = {
    vic-vpn = {
      connection = {
        id = "vic-vpn";
        type = "vpn";
        uuid = "68e0ab40-8b95-425f-95f0-75e41579ae01";
        autoconnect = false;
      };
      vpn = {
        service-type = "org.freedesktop.NetworkManager.openconnect";
        protocol = "anyconnect";
        gateway = "vpn.is.cvut.cz";
        authtype = "password";
        autoconnect-flags = "0";
        certsigs-flags = "0";
        cookie-flags = notSaved;
        gateway-flags = notSaved;
        gwcert-flags = notSaved;
        resolve-flags = notSaved;
        lasthost-flags = "0";
        xmlconfig-flags = "0";
        # TCP-only: silent UDP blackholes otherwise leave the tunnel up-but-dead.
        disable_udp = "yes";
        enable_csd_trojan = "no";
        pem_passphrase_fsid = "no";
        prevent_invalid_cert = "no";
        stoken_source = "disabled";
      };
      # Form pre-fills, not secrets; save_passwords sends the password to gnome-keyring.
      vpn-secrets = {
        "form:main:group_list" = "AnyConnect_VICpriv_cvut";
        "form:main:username" = ctuLogin;
        lasthost = "vpn.is.cvut.cz";
        save_passwords = "yes";
      };
      ipv4.method = "auto";
      ipv6 = {
        method = "auto";
        addr-gen-mode = "stable-privacy";
      };
    };

    fit-vpn = {
      connection = {
        id = "fit-vpn";
        type = "vpn";
        uuid = "8963a4d6-2a94-450c-95dc-c8ac6024d8f6";
        autoconnect = false;
      };
      vpn = {
        service-type = "org.freedesktop.NetworkManager.openvpn";
        connection-type = "password";
        remote = "vpn.fit.cvut.cz:1194:udp";
        verify-x509-name = "name:vpn.fit.cvut.cz";
        ca = fitCa;
        cipher = "AES-256-CBC";
        dev = "tun";
        connect-timeout = "2";
        push-peer-info = "yes";
        username = ctuLogin;
        password-flags = agentOwned;
        challenge-response-flags = notSaved;
      };
      # Split tunnel: only FIT subnets go through the VPN.
      ipv4 = {
        method = "auto";
        never-default = true;
      };
      ipv6 = {
        method = "auto";
        never-default = true;
        addr-gen-mode = "default";
      };
    };
  };
}
