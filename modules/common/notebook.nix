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
  ...
}: {
  # Upstream ships no [Install], so without this there is no pairing agent and BlueZ rejects device-initiated HID reconnects.
  systemd.user.services.blueman-applet = {
    serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.blueman}/bin/blueman-applet"
    ];
    after = ["graphical-session.target"];
    partOf = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];
  };

  services = {
    blueman.enable = true;
    power-profiles-daemon.enable = false;
    libinput.enable = true;
    tlp.enable = false;
    auto-cpufreq = {
      enable = lib.mkDefault true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
  };
  hardware = {
    acpilight.enable = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
  environment.systemPackages = with pkgs; [
    brightnessctl
  ];
}
