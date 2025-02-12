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
{pkgs, ...}: let
  # config_dir = ".config/hypr";
in {
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;
    settings = {
      # Keybinds
      # bind = [] ++ (builtins.concatLists (builtins.genList (i: let
      #   ws = i + 1;
      # in [
      #   "mod, code:1${toString i}, workspace, ${toString ws}"
      #   "mod SHIFT, code:1${toString i}, workspace, ${toString ws}"
      # ])));

      # Theme
      catppuccin = {
        enable = true;
        accent = "mauve";
        flavor = "mocha";
      };

      # autostart
      exec-once = [
        "nm-applet &"
        "hyprlock"
        "exec-once=waybar &"
        "swaync &"
        "hyprpaper &"
        "hypridle"
      ];

      input = {
        kb_layout = "us,cs";
        numlock_by_default = true;
        touchpad = {
          natural_scroll = true;
        };
      };

      general = {
        "$mainMod" = "SUPER";
      };
    };
  };
  home = {
    # file."${config_dir}/catppuccin.conf".source = ./catppuccin.conf;
    packages = with pkgs; [
      wayland
    ];
  };
  imports = [
    ../backgrounds
  ];
}
