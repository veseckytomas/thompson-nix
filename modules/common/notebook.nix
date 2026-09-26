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

  # Hosts that own their power policy set it themselves; these only keep other daemons from claiming it.
  services = {
    blueman.enable = true;
    power-profiles-daemon.enable = false;
    libinput.enable = true;
    tlp.enable = false;
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
