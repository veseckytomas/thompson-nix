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
  username,
  ...
}: let
  gateway = "vpn.net.cvut.cz:443";
  samlPort = 8020;
  unit = "cvut-vpn.service";
  samlUrl = "https://${gateway}/remote/saml/start?redirect=1";

  # Upstream hardcodes a 50 s SAML deadline (5 tries x 10 s); Entra MFA routinely needs longer.
  openfortivpn-patched = pkgs.openfortivpn.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        substituteInPlace src/http_server.c \
          --replace-fail 'int max_tries = 5;' 'int max_tries = 60;'
      '';
  });

  cvut-vpn = pkgs.writeShellApplication {
    name = "cvut-vpn";
    runtimeInputs = with pkgs; [systemd iproute2 gnugrep coreutils libnotify xdg-utils];
    text = ''
      unit="${unit}"

      notify() {
        notify-send --app-name="CVUT VPN" "$1" "''${2-}" 2>/dev/null || true
      }

      is_up() {
        ip -brief link show ppp0 >/dev/null 2>&1
      }

      status() {
        if is_up; then
          echo "connected"
        elif systemctl is-active --quiet "$unit"; then
          echo "connecting"
        else
          echo "disconnected"
        fi
      }

      up() {
        if is_up; then
          notify "Already connected"
          return 0
        fi
        if systemctl is-active --quiet "$unit"; then
          notify "SSO already in progress"
          return 0
        fi
        systemctl start "$unit"
        i=0
        while [ "$i" -lt 30 ]; do
          # Probe with ss, never a TCP connect: a connect is accepted and burns one of the 60 SAML tries.
          if ss -H -ltn "sport = :${toString samlPort}" | grep -q .; then
            break
          fi
          sleep 0.5
          i=$((i + 1))
        done
        if ! ss -H -ltn "sport = :${toString samlPort}" | grep -q .; then
          notify "VPN service failed to start"
          return 1
        fi
        xdg-open "${samlUrl}" 2>/dev/null || true
        notify "Complete the SSO in your browser"
      }

      down() {
        if systemctl stop "$unit"; then
          notify "Disconnected"
        else
          notify "Failed to disconnect"
          return 1
        fi
      }

      case "''${1-toggle}" in
        up | connect) up ;;
        down | disconnect) down ;;
        toggle)
          if [ "$(status)" = "disconnected" ]; then up; else down; fi
          ;;
        status) status ;;
        *)
          echo "usage: cvut-vpn [up|down|toggle|status]" >&2
          exit 2
          ;;
      esac
    '';
  };
in {
  environment.systemPackages = [cvut-vpn openfortivpn-patched];

  systemd.services.cvut-vpn = {
    description = "CVUT FortiGate VPN (SAML SSO)";
    # Never autostart: SSO needs an interactive browser session.
    serviceConfig = {
      Type = "simple";
      ExecStart = "${openfortivpn-patched}/bin/openfortivpn ${gateway} --saml-login=${toString samlPort}";
      Restart = "no";
      KillMode = "mixed";
      TimeoutStopSec = 15;
    };
    path = [pkgs.ppp pkgs.openresolv];
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units"
          && action.lookup("unit") == "${unit}"
          && subject.user == "${username}") {
        return polkit.Result.YES;
      }
    });
  '';
}
