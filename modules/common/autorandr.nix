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
  # An MST hub enumerates its outputs over several seconds, so the first udev event
  # reports a half-built topology; wait for xrandr to stop changing before switching.
  settle = pkgs.writeShellScript "autorandr-settle" ''
    PATH=${lib.makeBinPath [pkgs.xrandr pkgs.coreutils pkgs.gnugrep]}
    for _ in $(seq 1 30); do
      xrandr --query >/dev/null 2>&1 && break
      sleep 1
    done
    prev=""
    stable=0
    for _ in $(seq 1 30); do
      cur=$(xrandr --query 2>/dev/null | grep -E " connected| disconnected")
      if [ "$cur" = "$prev" ]; then
        stable=$((stable + 1))
        [ "$stable" -ge 3 ] && exit 0
      else
        stable=0
      fi
      prev=$cur
      sleep 1
    done
    exit 0
  '';
in {
  services = {
    # Enable automatic monitor hotplugging
    autorandr.enable = true;

    # Symlink XAUTHORITY to a predictable location so the autorandr service can find it
    xserver.displayManager.sessionCommands = ''
      ln -sfT "$XAUTHORITY" "$HOME/.Xauthority"
      ${pkgs.autorandr}/bin/autorandr --change
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
      ExecStartPre = settle;
      ExecStart = lib.mkForce "${pkgs.autorandr}/bin/autorandr --change";
    };
  };
}
