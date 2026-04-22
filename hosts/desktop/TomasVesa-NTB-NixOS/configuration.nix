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

    # Display and Input hotplug setup
    udev.extraRules = let
      displaySetup = pkgs.writeShellScript "display-setup.sh" ''
        export DISPLAY=:0
        export XAUTHORITY=/home/${username}/.Xauthority

        # Wait a bit for hardware/X to settle
        sleep 2

        monitor_cnt=$(${pkgs.xorg.xrandr}/bin/xrandr | grep ' connected' | wc -l)
        wacom_device="Wacom Intuos BT M Pen Pen (0x47803692)"
        wacom_pad="Wacom Intuos BT M Pad"

        # Apply Button Mapping for Wacom Pad
        ${pkgs.xorg.xinput}/bin/xinput set-button-map "$wacom_pad" 17 18 19 4 5 6 7 20

        # Apply Monitor Layout & Wacom Pen Mapping
        if [ "$monitor_cnt" -eq "3" ]; then
          ${pkgs.xorg.xrandr}/bin/xrandr --output DP-1-1 --mode 1920x1200 --primary --output DP-1-2 --mode 1920x1200 --right-of DP-1-1 --output eDP-1 --mode 1920x1200 --below DP-1-1
          ${pkgs.xorg.xinput}/bin/xinput map-to-output "$wacom_device" "DP-1-1"
        elif [ "$monitor_cnt" -eq "2" ]; then
          ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --mode 1920x1200 --primary --output DP-1 --right-of eDP-1
          ${pkgs.xorg.xinput}/bin/xinput map-to-output "$wacom_device" "eDP-1"
        elif [ "$monitor_cnt" -eq "4" ]; then
          ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --off --output DP-1-2 --primary --output DP-1-1-1 --right-of DP-1-2 --output DP-1-3-1 --left-of DP-1-2
          ${pkgs.xorg.xinput}/bin/xinput map-to-output "$wacom_device" "DP-1-2"
        else
          ${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --primary --mode 1920x1200
          ${pkgs.xorg.xinput}/bin/xinput map-to-output "$wacom_device" "eDP-1"
        fi
      '';
    in ''
      # Trigger on Wacom connection
      ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="Wacom Intuos BT M Pen Pen (0x47803692)", RUN+="${displaySetup}"

      # Trigger on Monitor connection/change
      ACTION=="change", SUBSYSTEM=="drm", RUN+="${displaySetup}"

      # MX Vertical connection log (optional)
      ACTION=="add", SUBSYSTEM=="input", ATTRS{name}=="MX Vertical", RUN+="${pkgs.writeShellScript "mx-vertical-hook.sh" ''
        echo "MX Vertical connected" > /tmp/mx-vertical-connection.log
      ''}"
    '';

    displayManager.sddm.autoNumlock = lib.mkForce false;
    # Numberpad config
    asus-numberpad-driver = {
      enable = true;
      layout = "up5401ea";
      wayland = false;
      runtimeDir = "/run/user/1000";
    };
  };

  users.users.${username}.extraGroups = ["input"];

  # System version
  system.stateVersion = "24.11";
}
