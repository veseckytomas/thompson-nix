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
  inputs,
  pkgs,
  ...
}: {
  boot.initrd.luks.devices."luks-ed07d8eb-0f44-43c0-9c1a-21ca61defdad".device = "/dev/disk/by-uuid/ed07d8eb-0f44-43c0-9c1a-21ca61defdad";
  services.borgbackup.jobs.rsync.paths = [
    "/mnt/hdd/bak"
    "/mnt/hdd/torrent"
    "/mnt/hdd_win/Data"
  ];

  # Gaming mouse configuration
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
}
