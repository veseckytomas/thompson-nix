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
  lib,
  config,
  ...
}: let
  busWaitSeconds = 60;

  # dbus-broker 37 can stall before sd_notify READY=1; systemd then fails dbus.service, which fails
  # NetworkManager's start job with result 'dependency'. Restart= cannot recover that: it only governs a
  # service whose own process exited, never a start job killed by a failed dependency (nor a BindsTo= stop).
  networkmanager-recover = pkgs.writeShellApplication {
    name = "networkmanager-recover";
    runtimeInputs = with pkgs; [systemd coreutils];
    text = ''
      # The bus usually returns immediately via dbus.socket activation, but this unit is triggered by the
      # failure itself, so wait for a usable bus instead of declaring Requires=dbus.service and inheriting it.
      i=0
      while [ "$i" -lt ${toString busWaitSeconds} ]; do
        if busctl --system --no-pager status >/dev/null 2>&1; then
          break
        fi
        sleep 1
        i=$((i + 1))
      done

      if ! busctl --system --no-pager status >/dev/null 2>&1; then
        echo "system bus still unavailable after ${toString busWaitSeconds}s; leaving NetworkManager alone" >&2
        exit 1
      fi

      systemctl restart NetworkManager.service

      # Additive and idempotent, but it exits 1 when NM was down, so re-run it to land the declarative profiles.
      systemctl restart NetworkManager-ensure-profiles.service || true

      # The boot transaction is already over; re-satisfy network-online.target for anything still ordered after it.
      systemctl start --no-block NetworkManager-wait-online.service || true
    '';
  };
in
  lib.mkIf config.networking.networkmanager.enable {
    systemd.services.dbus-broker.unitConfig.OnFailure = "networkmanager-recover.service";

    systemd.services.networkmanager-recover = {
      description = "Restore NetworkManager after a D-Bus failure";
      after = ["dbus.service"];
      unitConfig.JobTimeoutSec = busWaitSeconds + 60;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe networkmanager-recover;
      };
    };
  }
