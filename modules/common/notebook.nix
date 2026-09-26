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
}: let
  # intel_pstate HWP owns scaling, so the ASUS EC platform_profile is the only knob left worth driving.
  powerProfile = pkgs.writeShellScript "power-profile-auto" ''
    PATH=${lib.makeBinPath [pkgs.coreutils]}
    profile=/sys/firmware/acpi/platform_profile
    [ -w "$profile" ] || exit 0

    online=0
    for ac in /sys/class/power_supply/A{C,DP}*/online; do
      [ -r "$ac" ] && [ "$(cat "$ac")" = "1" ] && online=1
    done

    capacity=100
    [ -r /sys/class/power_supply/BAT0/capacity ] && capacity=$(cat /sys/class/power_supply/BAT0/capacity)

    current=$(cat "$profile")
    if [ "$online" = "1" ]; then
      want=performance
    elif [ "$capacity" -lt 50 ]; then
      want=quiet
    elif [ "$current" = "quiet" ] && [ "$capacity" -lt 55 ]; then
      # Hysteresis band keeps an integer capacity hovering at 50 from flapping the EC.
      want=quiet
    else
      want=balanced
    fi

    [ "$current" = "$want" ] || echo "$want" > "$profile"
  '';
in {
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
    # Match only the mains and internal battery; HID and USB-C PD supplies emit unrelated uevents.
    udev.extraRules = ''
      SUBSYSTEM=="power_supply", KERNEL=="AC*|BAT*", RUN+="${pkgs.systemd}/bin/systemctl --no-block start power-profile-auto.service"
    '';
  };

  systemd = {
    services.power-profile-auto = {
      description = "Set ASUS EC platform profile from power source and battery level";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = powerProfile;
      };
      wantedBy = ["multi-user.target"];
    };
    # A discharging battery crosses 50% with no uevent guaranteed, so poll as a backstop.
    timers.power-profile-auto = {
      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = "2min";
      };
      wantedBy = ["timers.target"];
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
