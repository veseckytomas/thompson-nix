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
{...}: {
  # Overrides the package's D-Bus-activated thunar.service so the daemon starts at login instead of on first launch.
  systemd.user.services.thunar = {
    Unit = {
      Description = "Thunar file manager daemon";
      # Ordered after the rclone mounts so the sidebar bookmarks under mnt/Onedrive warm their dir cache here, not in front of the first window.
      After = [
        "graphical-session.target"
        "rclone-onedrive.service"
        "rclone-protondrive.service"
      ];
      PartOf = ["graphical-session.target"];
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
    Service = {
      Type = "dbus";
      # Upstream claims this name second, so holding it means startup actually finished.
      BusName = "org.xfce.FileManager";
      # The system thunar-with-plugins, matching the binary the D-Bus activation file execs.
      ExecStart = "/run/current-system/sw/bin/Thunar --daemon";
      # Killing only the main process leaves spawned file operations alone.
      KillMode = "process";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
