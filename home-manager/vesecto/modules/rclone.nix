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
{pkgs, ...}: {
  home.packages = [pkgs.rclone];

  systemd.user.services.rclone-onedrive = {
    Unit = {
      Description = "rclone mount eOnedrive";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Install = {
      WantedBy = ["default.target"];
    };
    Service = {
      Type = "simple";
      # Clear any stale FUSE mount left over from an unclean exit (sleep/resume, network drop) before
      # mkdir, which itself fails with ENOTCONN on a stale endpoint. Without this cleanup the path stays
      # registered as a mountpoint, every restart fails its pre-check, and the unit crash-loops (err 107).
      # Must be the setuid wrapper, and fuse3 — the store-path fuse2 binary cannot unmount rclone's fuse3 mount.
      ExecStartPre = "/bin/sh -c '/run/wrappers/bin/fusermount3 -uz %h/mnt/Onedrive 2>/dev/null || true; ${pkgs.coreutils}/bin/mkdir -p %h/mnt/Onedrive'";
      ExecStart = "${pkgs.rclone}/bin/rclone mount eOnedrive2: %h/mnt/Onedrive --vfs-cache-mode writes --dir-cache-time 1000h --poll-interval 15s --timeout 1h --umask 002 --exclude '.omo/**'";
      ExecStop = "/run/wrappers/bin/fusermount3 -uz %h/mnt/Onedrive";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  systemd.user.services.rclone-protondrive = {
    Unit = {
      Description = "rclone mount ProtonDrive";
      After = ["network-online.target"];
      Wants = ["network-online.target"];
    };
    Install = {
      WantedBy = ["default.target"];
    };
    Service = {
      Type = "notify";
      # Unmount before mkdir: a stale endpoint makes mkdir fail with ENOTCONN. Must be the setuid wrapper, and fuse3 — the store-path fuse2 binary cannot unmount rclone's fuse3 mount unprivileged.
      ExecStartPre = "/bin/sh -c '/run/wrappers/bin/fusermount3 -uz %h/mnt/ProtonDrive 2>/dev/null || true; ${pkgs.coreutils}/bin/mkdir -p %h/mnt/ProtonDrive'";
      # protondrive has no ChangeNotify and its backend cache never invalidates under VFS, so caching is off and dir-cache is short instead of 1000h.
      ExecStart = "${pkgs.rclone}/bin/rclone mount ProtonDrive: %h/mnt/ProtonDrive --protondrive-enable-caching=false --protondrive-replace-existing-draft=true --vfs-cache-mode writes --dir-cache-time 5m --timeout 1h --umask 002";
      ExecStop = "/run/wrappers/bin/fusermount3 -uz %h/mnt/ProtonDrive";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
