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
{lib, ...}: let
  config_dir = ".config/qtile";
in {
  imports = [
    ../backgrounds
    ../i3lock
    ../rofi
    ../xbindkeys
  ];
  home = {
    sessionVariables = {
      XDG_CURRENT_DESKTOP = "qtile";
      XDG_SESSION_DESKTOP = "qtile";
      DESKTOP_SESSION = "qtile";
      XDG_SESSION_TYPE = "x11";
    };
    file = {
      "${config_dir}/config.py".source = ./config.py;
      "${config_dir}/colors.py".source = ./colors.py;
      "${config_dir}/autostart.sh".source = ./autostart.sh;
      "${config_dir}/setup.sh".source = ./setup.sh;
    };
  };

  # Store files all carry mtime=1, so Python keeps stale .pyc across generations.
  home.activation.dropQtilePycache = lib.hm.dag.entryAfter ["linkGeneration"] ''
    run rm -rf "$HOME/${config_dir}/__pycache__"
  '';
}
