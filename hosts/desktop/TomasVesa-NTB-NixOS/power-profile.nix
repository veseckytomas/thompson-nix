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
  # intel_pstate HWP scales the silicon; the ASUS EC platform_profile sets the thermal envelope it scales within.
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
      epp=performance
      boost=1
      no_c10=1
    elif [ "$capacity" -lt 50 ]; then
      want=quiet
      epp=power
      boost=0
      no_c10=0
    elif [ "$current" = "quiet" ] && [ "$capacity" -lt 55 ]; then
      # Hysteresis band keeps an integer capacity hovering at 50 from flapping the EC.
      want=quiet
      epp=power
      boost=0
      no_c10=0
    else
      want=balanced
      epp=balance_power
      boost=0
      no_c10=0
    fi

    [ "$current" = "$want" ] || echo "$want" > "$profile"

    # EPP rejects writes unless the governor is powersave, which is the intel_pstate HWP default.
    for c in /sys/devices/system/cpu/cpu*/cpufreq; do
      [ "$(cat "$c"/scaling_governor 2>/dev/null)" = "powersave" ] || continue
      pref=$c/energy_performance_preference
      [ -w "$pref" ] && [ "$(cat "$pref" 2>/dev/null)" != "$epp" ] && echo "$epp" > "$pref"
    done

    hwp=/sys/devices/system/cpu/intel_pstate/hwp_dynamic_boost
    [ -w "$hwp" ] && [ "$(cat "$hwp" 2>/dev/null)" != "$boost" ] && echo "$boost" > "$hwp"

    # C10 costs 310us to exit vs C6's 140us; park it on AC to cut wake latency, restore it on battery.
    for s in /sys/devices/system/cpu/cpu*/cpuidle/state*; do
      [ "$(cat "$s"/name 2>/dev/null)" = "C10" ] || continue
      [ -w "$s"/disable ] && [ "$(cat "$s"/disable 2>/dev/null)" != "$no_c10" ] && echo "$no_c10" > "$s"/disable
    done

    # auto-cpufreq used to park this at 1 on AC; assert it so turbo is never left disabled.
    turbo=/sys/devices/system/cpu/intel_pstate/no_turbo
    [ -w "$turbo" ] && [ "$(cat "$turbo" 2>/dev/null)" != "0" ] && echo 0 > "$turbo"

    exit 0
  '';
in {
  # Match only the mains and internal battery; HID and USB-C PD supplies emit unrelated uevents.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="AC*|BAT*", RUN+="${pkgs.systemd}/bin/systemctl --no-block start power-profile-auto.service"
  '';

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
}
