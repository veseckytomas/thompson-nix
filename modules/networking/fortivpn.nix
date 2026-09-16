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

  # openfortivpn prints the SAML URL but never opens it; we tail the journal and launch the browser.
  cvut-vpn = pkgs.writeShellApplication {
    name = "cvut-vpn";
    runtimeInputs = with pkgs; [systemd iproute2 gnugrep gnused coreutils libnotify];
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

      # The URL only appears once, so watch the journal from now and open the first match.
      open_browser() {
        local url
        url=$(timeout 60 journalctl --unit="$unit" --since=now --follow --output=cat 2>/dev/null \
          | grep --line-buffered --max-count=1 -oE 'https://[^ ]*/remote/saml/start[^ ]*') || true
        if [ -n "$url" ]; then
          xdg-open "$url" >/dev/null 2>&1 || notify "Open this URL to log in" "$url"
        else
          notify "No SAML URL found" "Check: journalctl -u $unit"
        fi
      }

      up() {
        if is_up; then
          notify "Already connected"
          return 0
        fi
        systemctl start --no-block "$unit"
        notify "Connecting…" "Finish SSO in the browser"
        open_browser
      }

      down() {
        systemctl stop "$unit"
        notify "Disconnected"
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
  environment.systemPackages = [cvut-vpn pkgs.openfortivpn];

  systemd.services.cvut-vpn = {
    description = "CVUT FortiGate VPN (SAML SSO)";
    # Never autostart: SSO needs an interactive browser session.
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.openfortivpn}/bin/openfortivpn ${gateway} --saml-login=${toString samlPort} --persistent=10";
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
