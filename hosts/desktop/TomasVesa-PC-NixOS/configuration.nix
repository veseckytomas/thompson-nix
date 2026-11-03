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
  boot.initrd.luks.devices."luks-ed07d8eb-0f44-43c0-9c1a-21ca61defdad".device = "/dev/disk/by-uuid/ed07d8eb-0f44-43c0-9c1a-21ca61defdad";
  services.borgbackup.jobs.rsync.paths = [
    "/mnt/hdd/bak"
  ];
}
