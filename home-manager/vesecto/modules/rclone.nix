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
      ExecStartPre = "/bin/sh -c '${pkgs.coreutils}/bin/mkdir -p %h/mnt/Onedrive && ! ${pkgs.utillinux}/bin/mountpoint -q %h/mnt/Onedrive'";
      ExecStart = "${pkgs.rclone}/bin/rclone mount eOnedrive: %h/mnt/Onedrive --vfs-cache-mode full";
      ExecStop = "${pkgs.fuse}/bin/fusermount -u %h/mnt/Onedrive";
      Restart = "on-failure";
      RestartSec = "30s";
    };
  };
}
