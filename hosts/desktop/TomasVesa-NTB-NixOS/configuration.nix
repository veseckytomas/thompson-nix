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
  lib,
  ...
}: {
  boot.initrd.luks.devices."luks-75e7b65c-68bb-4801-b9ec-49403d21ede5".device = "/dev/disk/by-uuid/75e7b65c-68bb-4801-b9ec-49403d21ede5";

  systemd.services.asus-numberpad-driver = {
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = lib.mkForce "1s";
    };
  };

  # Allow restarting the service without password
  security.sudo.extraRules = [
    {
      users = ["${username}"];
      commands = [
        {
          command = "${pkgs.systemd}/bin/systemctl restart asus-numberpad-driver";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # MX Vertical settings
  services = {
    xserver.inputClassSections = [
      ''
        Identifier "MX Vertical"
        MatchProduct "MX Vertical"
        Driver "libinput"
        Option "AccelSpeed" "-0.7"
      ''
    ];

    # Enable automatic monitor hotplugging
    autorandr.enable = true;

    displayManager.sddm.autoNumlock = lib.mkForce false;
    # Numberpad config
    asus-numberpad-driver = {
      enable = true;
      layout = "up5401ea";
      wayland = false;
      runtimeDir = "/run/user/1000";
    };
  };

  # Fix autorandr service XAUTHORITY detection
  systemd.services.autorandr = {
    path = with pkgs; [ coreutils procps gnugrep gawk ];
    serviceConfig.ExecStart = lib.mkForce (pkgs.writeShellScript "autorandr-wrapper" ''
      export DISPLAY=:0
      # Dynamically determine XAUTHORITY from the running window manager (qtile)
      WM_PID=$(pgrep -u ${username} -x qtile | head -n1)
      if [ -n "$WM_PID" ]; then
        export XAUTHORITY=$(cat /proc/$WM_PID/environ | tr '\0' '\n' | grep '^XAUTHORITY=' | cut -d= -f2)
      fi
      
      # Fallback to a common location if not found
      if [ -z "$XAUTHORITY" ]; then
        export XAUTHORITY=/home/${username}/.Xauthority
      fi

      if [ -f "$XAUTHORITY" ]; then
        exec ${pkgs.autorandr}/bin/autorandr --batch --change --default default
      else
        echo "XAUTHORITY not found or not accessible: $XAUTHORITY"
        exit 1
      fi
    '');
  };

  users.users.${username}.extraGroups = ["input"];

  # System version
  system.stateVersion = "24.11";
}
