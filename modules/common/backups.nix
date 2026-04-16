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
{hostname, ...}: {
  # Enable automatic backups to rsync.net
  services.borgbackup.jobs = {
    rsync = {
      paths = [
        "/home/vesecto/DataGripProjects"
        "/home/vesecto/Documents"
        "/home/vesecto/Downloads"
        "/home/vesecto/Git"
        "/home/vesecto/pentaho"
        "/home/vesecto/.setup.sh"
      ];
      user = "root";
      group = "root";
      doInit = true;
      startAt = [
        "daily"
      ];
      inhibitsSleep = true;
      persistentTimer = true;

      repo = "zh5849@zh5849.rsync.net:${hostname}";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/trust/borg/passphrase";
      };
      compression = "auto,lz4";
      prune = {
        keep = {
          daily = 7;
          weekly = 4;
          monthly = 12;
          yearly = 10;
        };
      };
      extraArgs = [
        "--remote-path=borg14"
      ];
    };
  };

  systemd.services.borgbackup-job-rsync = {
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "5m";
    };
  };

  environment.sessionVariables.BORG_REMOTE_PATH = "borg14";
}
