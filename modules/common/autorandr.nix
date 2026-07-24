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
}: {
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
      # Wait for X auth to be reachable, then let MST/hotplug outputs settle; coalesces the udev event burst into one run
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do ${pkgs.xrandr}/bin/xrandr --query >/dev/null 2>&1 && break; ${pkgs.coreutils}/bin/sleep 1; done; ${pkgs.coreutils}/bin/sleep 2'";
      ExecStart = lib.mkForce "${pkgs.autorandr}/bin/autorandr --change";
    };
  };
}
