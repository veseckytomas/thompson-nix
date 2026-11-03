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
{pkgs, ...}: let
  wacom-map = pkgs.writeShellApplication {
    name = "wacom-map";
    runtimeInputs = with pkgs; [xinput xrandr gawk];
    text = ''
      # Never `exit` out of awk here: it SIGPIPEs xrandr, and pipefail+errexit then abort the script.
      primary=$(xrandr --query | awk '/ connected primary/ && !seen {print $1; seen=1}')
      if [ -z "$primary" ]; then
        primary=$(xrandr --query | awk '/ connected/ && !seen {print $1; seen=1}')
      fi
      if [ -z "$primary" ]; then
        echo "wacom-map: no connected output" >&2
        exit 1
      fi

      # Address devices by id: USB and Bluetooth expose identical names, so a name lookup is ambiguous.
      while read -r id; do
        name=$(xinput --list --name-only "$id" 2>/dev/null) || continue
        case "$name" in
          *Wacom*Pad)
            xinput set-button-map "$id" 17 18 19 4 5 6 7 20 >/dev/null 2>&1 || true
            ;;
          *Wacom*)
            xinput map-to-output "$id" "$primary" >/dev/null 2>&1 || true
            ;;
        esac
      done < <(xinput --list --id-only)
    '';
  };

  wacom-hotplug = pkgs.writeShellApplication {
    name = "wacom-hotplug";
    runtimeInputs = [wacom-map pkgs.coreutils];
    text = ''
      event=''${1-}
      name=''${4-}
      case "$event" in
        XIDeviceEnabled | XISlaveAdded) ;;
        *) exit 0 ;;
      esac
      case "$name" in
        *Wacom*) ;;
        *) exit 0 ;;
      esac
      # The X server settles the device (and its virtual stylus subdevice) shortly after announcing it.
      sleep 0.5
      wacom-map
    '';
  };
in {
  home.packages = [wacom-map];

  # Bluetooth pairs long after the autorandr hook ran, and the stylus is a virtual subdevice created
  # only on first pen proximity, so remap on XInput hierarchy events rather than on display changes.
  systemd.user.services.wacom-hotplug = {
    Unit = {
      Description = "Map Wacom tablet to the primary output on hotplug";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      # -0 replays the already-plugged devices, covering a tablet connected before the session started.
      ExecStart = "${pkgs.inputplug}/bin/inputplug -d -0 -c ${wacom-hotplug}/bin/wacom-hotplug";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  programs.autorandr.hooks.postswitch."10_wacom-setup" = "${wacom-map}/bin/wacom-map || true";
}
