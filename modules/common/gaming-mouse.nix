#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  config,
  inputs,
  pkgs,
  lib,
  username,
  ...
}: {
  # ratbagd and piper are pinned to flake inputs for newer device support than nixpkgs ships.
  services.ratbagd = {
    enable = true;
    package = pkgs.libratbag.overrideAttrs (old: {
      src = inputs.ratbagd;
    });
  };

  environment.systemPackages = with pkgs; [
    (piper.overrideAttrs
      (old: {
        src = inputs.piper;
      }))
  ];

  # ratbagd exits after 30s dbus-idle by default; keep it wanted so a udev-triggered reassert always has someone to talk to.
  # Never override ExecStart here: the package unit already provides one, and a second line on a
  # non-oneshot unit is rejected with "bad unit file setting" — the daemon then never starts.
  systemd.services.ratbagd.wantedBy = ["multi-user.target"];

  # G502's active DPI index is volatile: re-enumeration (KVM switch) drops it back to the flash default.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="hid", ENV{HID_ID}=="0003:0000046D:0000407F", TAG+="systemd", ENV{SYSTEMD_WANTS}+="g502-dpi.service"
  '';

  systemd.services.g502-dpi = {
    description = "Reassert G502 DPI index after re-enumeration";
    serviceConfig = {
      Type = "oneshot";
      # Runs as the user so ratbagctl sees the same ~/.config and dbus session-owned ratbagd.
      User = username;
      ExecStart = pkgs.writeShellScript "g502-dpi-restore" ''
        PATH=${lib.makeBinPath [config.services.ratbagd.package pkgs.coreutils pkgs.gnugrep]}
        ratbagctl="${config.services.ratbagd.package}/bin/ratbagctl"
        # The mouse can lag the receiver's hid node; poll instead of failing hard on a stale scan.
        for _ in $(seq 1 5); do
          dev="$("$ratbagctl" list 2>/dev/null | grep -i 'G502' | head -1 | cut -d: -f1)"
          [ -n "$dev" ] || {
            sleep 1
            continue
          }
          exec "$ratbagctl" "$dev" resolution active set 0
        done
        # No G502 in reach (e.g. currently bolt-linked elsewhere): leave, a power-cycle re-pairs it.
        exit 0
      '';
    };
  };
}
