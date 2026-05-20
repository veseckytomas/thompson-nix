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

    # Symlink XAUTHORITY to a predictable location so autorandr service can find it
    xserver.displayManager.sessionCommands = ''
      ln -sfT "$XAUTHORITY" "$HOME/.Xauthority"
      ${pkgs.autorandr}/bin/autorandr --change
    '';
  };

  # Rate limit autorandr service to prevent spam-restarts from udev
  systemd.services.autorandr = {
    unitConfig = {
      StartLimitIntervalSec = lib.mkForce 5;
      StartLimitBurst = lib.mkForce 1;
    };
    serviceConfig = {
      User = username;
      # Reuse XAUTHORITY and DISPLAY from the symlink and default
      Environment = [
        "DISPLAY=:0"
        "XAUTHORITY=/home/${username}/.Xauthority"
      ];
      ExecStart = lib.mkForce "${pkgs.autorandr}/bin/autorandr --change --default default";
    };
  };

  users.users.${username}.extraGroups = ["input"];

  # Enable ollama on NTB
  services.ollama.enable = true;
}
