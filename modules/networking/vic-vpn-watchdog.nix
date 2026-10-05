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
{pkgs, ...}: let
  watchdog = pkgs.writeShellScript "vic-vpn-watchdog" ''
    nmcli=${pkgs.networkmanager}/bin/nmcli
    curl=${pkgs.curl}/bin/curl
    grep=${pkgs.gnugrep}/bin/grep
    sleep=${pkgs.coreutils}/bin/sleep

    # Only heal a tunnel the user intentionally brought up; never auto-connect.
    $nmcli -t -f NAME,TYPE connection show --active | $grep -q '^vic-vpn:vpn' || exit 0

    # Any HTTP status (401 expected) proves reachability; 000 means blackhole.
    probe() { $curl --noproxy '*' -sS -o /dev/null -m 10 https://llm.is.cvut.cz/v1/models; }

    # One retry per run: a single flap must not cycle the VPN.
    probe || { $sleep 5; probe; } && exit 0

    echo "endpoint unreachable through active tunnel, cycling vic-vpn"
    $nmcli connection down vic-vpn || true
    $sleep 2
    $nmcli connection up vic-vpn || true
    $sleep 5
    if probe; then
      echo "tunnel recovered"
    else
      echo "still unreachable after cycle, manual auth may be required"
    fi
  '';
in {
  systemd.user.services.vic-vpn-watchdog = {
    description = "Heal vic-vpn when the tunnel is up but the LLM endpoint is unreachable";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = watchdog;
    };
  };

  systemd.user.timers.vic-vpn-watchdog = {
    description = "Probe vic-vpn tunnel health";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "30s";
    };
  };
}
