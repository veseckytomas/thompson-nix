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
{...}: let
  mod = "SUPER";
  terminal = "kitty";
  launcher = "";
  screenshot = "";
  powermenu = "";
  file_manager = "thunar";
  run_terminal = terminal + " -e tmux";
  browser = "librewolf";
  editor = terminal + " -e nvim";
  music_player = "spotify";
  bluetooth = "blueman-manager";
  calculator = "qalculate-gtk";
  keyboard_layout = "us";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "${mod}";
    };
  };
}
