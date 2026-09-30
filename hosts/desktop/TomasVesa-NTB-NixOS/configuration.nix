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
  username,
  lib,
  pkgs,
  ...
}: let
  # disable_due_inactivity_time=0: timer compares against last *touchpad* event, which activation never
  # refreshes, so any value kills the numpad on the next tick when idle longer than it.
  numberpadDefaults = pkgs.writeText "numberpad_dev" ''
    [main]
    disable_due_inactivity_time = 0
    touchpad_disables_numpad = 0
    sys_numlock_enables_numpad = 0
    numpad_disables_sys_numlock = 0
  '';

  # Upstream's ExecStartPre skips non-empty files, so a once-seeded read-only copy stays 444 forever.
  numberpadSeed = pkgs.writeShellScript "asus-numberpad-seed" ''
    set -eu
    cfg="$1"
    stamp="$(dirname "$cfg")/.nix-stamp"
    want="${numberpadDefaults}"
    if [ ! -s "$cfg" ] || [ ! -w "$cfg" ] || [ "$(cat "$stamp" 2>/dev/null || true)" != "$want" ]; then
      ${pkgs.coreutils}/bin/install -m 644 "$want" "$cfg"
      printf '%s' "$want" > "$stamp"
    fi
  '';
in {
  boot.initrd.luks.devices."luks-75e7b65c-68bb-4801-b9ec-49403d21ede5".device = "/dev/disk/by-uuid/75e7b65c-68bb-4801-b9ec-49403d21ede5";

  systemd.user.services.asus-numberpad-driver = {
    # Only consumer is enabled_touchpad_pointer=3 toggling libinput tap-to-click.
    path = [pkgs.xinput];

    # Driver SIGUSR1s itself when X goes away; stock 5-per-10s tripped the unit into failed on restart.
    unitConfig = {
      StartLimitBurst = lib.mkForce 10;
      StartLimitIntervalSec = lib.mkForce 300;
    };

    serviceConfig = {
      Restart = lib.mkForce "on-failure";
      RestartSec = lib.mkForce "3s";
      ExecStartPre = lib.mkForce "${numberpadSeed} %E/asus-numberpad-driver/numberpad_dev";
    };
  };

  # MX Vertical settings
  services = {
    # LVFS query/apply path for a Micron 2550 firmware fix (drive on V3MA101); drop once resolved.
    fwupd.enable = true;

    xserver.inputClassSections = [
      ''
        Identifier "MX Vertical"
        MatchProduct "MX Vertical"
        Driver "libinput"
        Option "AccelSpeed" "-0.7"
      ''
    ];

    displayManager.sddm.autoNumlock = lib.mkForce false;
  };

  # Numberpad config
  hardware.asus-numberpad-driver = {
    enable = true;
    layout = "up5401ea";
    wayland = false;
    runtimeDir = "/run/user/1000";
  };

  users.users.${username}.extraGroups = ["input"];
}
