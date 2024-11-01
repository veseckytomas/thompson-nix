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
  home = {
    username = "vesecto";
    homeDirectory = "/home/vesecto";
    stateVersion = "24.05";
    sessionVariables = {
      EDITOR = "nvim";
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
  };
  xdg = {
    enable = true;
    mimeApps = {
      enable = true;
      associations.added = {
        "application/pdf" = ["org.gnome.Evince.desktop"];
        "text/html" = ["librewolf.desktop"];
        "application/xhtml+xml" = ["librewolf.desktop"];
        "x-scheme-handler/http" = ["librewolf.desktop;"];
        "x-scheme-handler/https" = ["librewolf.desktop"];
        "x-scheme-handler/mailto" = ["userapp-Thunderbird-SLK2Q2.desktop"];
        "image/png" = ["org.nomacs.ImageLounge.desktop"];
        "image/jpeg" = ["org.nomacs.ImageLounge.desktop"];
        "x-scheme-handler/webcal" = ["userapp-Thunderbird-7FS1Q2.desktop"];
        "text/calendar" = ["userapp-Thunderbird-7FS1Q2.desktop"];
        "text/plain" = ["nvim.desktop"];
        "video/mp4" = ["vlc.desktop"];
      };
      defaultApplications = {
        "application/pdf" = ["org.gnome.Evince.desktop"];
        "text/html" = ["librewolf.desktop"];
        "application/xhtml+xml" = ["librewolf.desktop"];
        "x-scheme-handler/http" = ["librewolf.desktop;"];
        "x-scheme-handler/https" = ["librewolf.desktop"];
        "x-scheme-handler/mailto" = ["userapp-Thunderbird-SLK2Q2.desktop"];
        "image/png" = ["org.nomacs.ImageLounge.desktop"];
        "image/jpeg" = ["org.nomacs.ImageLounge.desktop"];
        "x-scheme-handler/webcal" = ["userapp-Thunderbird-7FS1Q2.desktop"];
        "text/calendar" = ["userapp-Thunderbird-7FS1Q2.desktop"];
        "text/plain" = ["nvim.desktop"];
        "video/mp4" = ["vlc.desktop"];
      };
    };
  };

  news.display = "silent";
  programs.home-manager.enable = true;

  imports = [
    ./modules
  ];
}
