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
{username, ...}: {
  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
    shell.enableZshIntegration = true;
    sessionVariables = {
      EDITOR = "nvim";
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
    pointerCursor = {
      enable = true;
      x11.enable = true;
      gtk.enable = true;
      size = 32;
    };
  };
  xdg = {
    enable = true;
    configFile."mimeapps.list".force = true;
    mimeApps = {
      enable = true;
      associations.added = {
        "application/pdf" = ["org.gnome.Evince.desktop"];
        "image/png" = ["org.nomacs.ImageLounge.desktop"];
        "image/jpeg" = ["org.nomacs.ImageLounge.desktop"];
        "text/plain" = ["nvim.desktop"];
        "video/mp4" = ["vlc.desktop"];
        "text/html" = ["librewolf.desktop"];
        "x-scheme-handler/http" = ["librewolf.desktop"];
        "x-scheme-handler/https" = ["librewolf.desktop"];
        "x-scheme-handler/about" = ["librewolf.desktop"];
        "x-scheme-handler/unknown" = ["librewolf.desktop"];
      };
      defaultApplications = {
        "application/pdf" = ["org.gnome.Evince.desktop"];
        "image/png" = ["org.nomacs.ImageLounge.desktop"];
        "image/jpeg" = ["org.nomacs.ImageLounge.desktop"];
        "text/plain" = ["nvim.desktop"];
        "video/mp4" = ["vlc.desktop"];
        "text/html" = ["librewolf.desktop"];
        "x-scheme-handler/http" = ["librewolf.desktop"];
        "x-scheme-handler/https" = ["librewolf.desktop"];
        "x-scheme-handler/about" = ["librewolf.desktop"];
        "x-scheme-handler/unknown" = ["librewolf.desktop"];
      };
    };
  };

  news.display = "silent";
  programs.home-manager.enable = true;
}
