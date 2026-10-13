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
  lib,
  username,
  ...
}: let
  # MST sink names follow the USB-C port used (DP-1-* vs DP-2-*), and a closed lid blanks eDP-1's EDID.
  matchFlags = "--match-edid --ignore-lid";
  # A start request against the running oneshot is a no-op, so retry inside the run instead.
  converge = pkgs.writeShellScript "autorandr-converge" ''
    PATH=${lib.makeBinPath [pkgs.autorandr pkgs.xrandr pkgs.coreutils pkgs.gnugrep]}
    topology() { xrandr --query 2>/dev/null | grep -E " connected| disconnected"; }

    # Nothing to converge until X accepts us: udev fires this before the session writes .Xauthority.
    ready=0
    for _ in $(seq 1 30); do
      xrandr --query >/dev/null 2>&1 && {
        ready=1
        break
      }
      sleep 1
    done
    # The session's own `autorandr --change` covers this boot, so leave rather than log an auth failure.
    [ "$ready" -eq 1 ] || exit 0

    prev=""
    stable=0
    # 40s ceiling: longer than the ~10s enumeration, short enough not to outlive a dock/undock.
    for _ in $(seq 1 40); do
      cur=$(topology)
      if [ "$cur" = "$prev" ]; then
        stable=$((stable + 1))
      else
        # Topology moved: apply now so a half-built dock still gets a best-effort layout.
        stable=0
        autorandr --change ${matchFlags} || true
      fi
      prev=$cur
      # Three quiet samples in a row means enumeration finished; apply once more and stop.
      if [ "$stable" -ge 3 ]; then
        autorandr --change ${matchFlags} || true
        # Re-apply only if the final apply itself perturbed the topology (e.g. a mode set).
        [ "$(topology)" = "$cur" ] && exit 0
        stable=0
      fi
      sleep 1
    done
    autorandr --change ${matchFlags} || true
    exit 0
  '';
in {
  services = {
    # Enable automatic monitor hotplugging
    autorandr.enable = true;

    # Symlink XAUTHORITY to a predictable location so the autorandr service can find it
    xserver.displayManager.sessionCommands = ''
      ln -sfT "$XAUTHORITY" "$HOME/.Xauthority"
      ${pkgs.autorandr}/bin/autorandr --change ${matchFlags}
    '';

    # MST sinks are created, not changed, on plug, and autorandr's own rule only matches "change".
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_connector", RUN+="${pkgs.systemd}/bin/systemctl start --no-block autorandr.service"
    '';
  };

  systemd.services.autorandr = {
    # Module default of 1 start / 5s drops the udev event burst an MST hotplug emits
    startLimitIntervalSec = lib.mkForce 30;
    startLimitBurst = lib.mkForce 10;
    serviceConfig = {
      User = username;
      # Reuse XAUTHORITY and DISPLAY from the session symlink
      Environment = [
        "DISPLAY=:0"
        "XAUTHORITY=/home/${username}/.Xauthority"
      ];
      # No --default: an unmatched topology then keeps the current layout instead of blanking the dock.
      ExecStart = lib.mkForce converge;
    };
  };
}
