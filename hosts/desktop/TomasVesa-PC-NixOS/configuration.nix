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
{...}: {
  boot.initrd.luks.devices."luks-539c0859-dfb0-4823-8333-066792c99c43".device = "/dev/disk/by-uuid/539c0859-dfb0-4823-8333-066792c99c43";
  networking.hostName = "TomasVesa-PC-NixOS";
  # services.borgbackup.jobs.rsync.paths = [
  #   "/mnt/hdd/bak"
  #   "/mnt/hdd_win/Data"
  # ];

  # System version
  system.stateVersion = "24.05";
}
