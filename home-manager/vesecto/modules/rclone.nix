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
      # Ensure the mountpoint exists, then clear any stale FUSE mount left over
      # from an unclean exit (sleep/resume, network drop). Without this cleanup a
      # stale endpoint keeps the path registered as a mountpoint, every restart
      # fails its pre-check, and the unit crash-loops forever (ENOTCONN / err 107).
      ExecStartPre = "/bin/sh -c '${pkgs.coreutils}/bin/mkdir -p %h/mnt/Onedrive; ${pkgs.fuse}/bin/fusermount -uz %h/mnt/Onedrive 2>/dev/null || true'";
      ExecStart = "${pkgs.rclone}/bin/rclone mount eOnedrive: %h/mnt/Onedrive --vfs-cache-mode writes --dir-cache-time 1000h --poll-interval 15s --timeout 1h --umask 002";
      ExecStop = "${pkgs.fuse}/bin/fusermount -uz %h/mnt/Onedrive";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
