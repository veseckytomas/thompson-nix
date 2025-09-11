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
  # Enable automatic backups to rsync.net
  services.borgbackup.jobs = {
    rsync = {
      paths = [
        "/home/vesecto/DataGripProjects"
        "/home/vesecto/Documents"
        "/home/vesecto/Downloads"
        "/home/vesecto/Git"
        "/home/vesecto/mnt"
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

      repo = "<rsync.net user>@<rsync.net server ip>:<path to repo name>";
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
      # extraArgs = [
      #   "--remote-path=borg14"
      # ];
    };
  };

  environment.sessionVariables.BORG_REMOTE_PATH = "borg14";
}
