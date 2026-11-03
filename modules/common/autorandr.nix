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
  username,
  ...
}: let
  # MST sink names follow the USB-C port used (DP-1-* vs DP-2-*), and a closed lid blanks eDP-1's EDID.
  matchFlags = "--match-edid --ignore-lid";
  converge = pkgs.writeShellScript "autorandr-converge" ''
    PATH=${lib.makeBinPath [pkgs.autorandr pkgs.xrandr pkgs.coreutils pkgs.gnugrep pkgs.util-linux pkgs.dbus]}
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
        stable=0
      fi
      prev=$cur
      # Five quiet 1s samples: a KVM re-plans its MST streams in bursts spread over several seconds.
      [ "$stable" -ge 5 ] && break
      sleep 1
    done

    # --force skips autorandr's "config already loaded" exit: KMS can match while an MST payload is blank.
    autorandr --change ${matchFlags} --force || true

    # Payload kick: a real OFF/ON re-plans the stream a silent MST drop left dark; the brief blank is accepted.
    for profile in $(autorandr --current 2>/dev/null); do
      config="$HOME/.config/autorandr/$profile/config"
      [ -r "$config" ] || config="/etc/xdg/autorandr/$profile/config"
      [ -r "$config" ] || continue
      name=""
      off=0
      while IFS= read -r line; do
        case $line in
          "output "*)
            [ -z "$name" ] || [ "$off" -eq 1 ] || xrandr --output "$name" --off
            name=''${line#output }
            off=0
            ;;
          off) off=1 ;;
        esac
      done < "$config"
      [ -z "$name" ] || [ "$off" -eq 1 ] || xrandr --output "$name" --off
    done
    sleep 0.4
    autorandr --change ${matchFlags} --force || true
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

    # Every connector event re-arms the timer, so the last event of a burst wins and no uevent is swallowed.
    udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="drm", ENV{DEVTYPE}=="drm_connector", RUN+="${pkgs.systemd}/bin/systemctl --no-block restart autorandr-trigger.timer"
    '';
  };

  systemd = {
    services = {
      # nixpkgs's 40-monitor-hotplug.rules still starts this unit on "change", so it is parked as a no-op.
      autorandr.serviceConfig.ExecStart = lib.mkForce "${pkgs.coreutils}/bin/true";
      autorandr-converge = {
        description = "Apply the detected autorandr profile once the topology is stable";
        startLimitIntervalSec = lib.mkForce 0;
        serviceConfig = {
          Type = "oneshot";
          User = username;
          # Reuse XAUTHORITY and DISPLAY from the session symlink
          Environment = [
            "DISPLAY=:0"
            "XAUTHORITY=/home/${username}/.Xauthority"
          ];
          ExecStart = converge;
        };
      };
    };
    timers.autorandr-trigger = {
      description = "Debounce window between the last DRM connector uevent and the converge run";
      timerConfig = {
        OnActiveSec = 5;
        Unit = "autorandr-converge.service";
      };
    };
  };
}
