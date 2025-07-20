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
  services.flameshot = {
    enable = true;
    settings = {
      General = {
        autoCloseIdleDaemon = false;
        contrastOpacity = 188;
        disabledTrayIcon = true;
        savePath = "/home/vesecto/mnt/Onedrive/Pictures/Screenshots";
        showDesktopNotification = false;
        showStartupLaunchMessage = false;
        startupLaunch = true;
      };
    };
  };
}
