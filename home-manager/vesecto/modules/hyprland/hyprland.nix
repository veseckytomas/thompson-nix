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
  config,
  pkgs,
  lib,
  ...
}: let
  mod = "SUPER";
  terminal = "kitty -e tmux";
  browser = "librewolf";
  editor = "kitty -e nvim";
  fileManager = "thunar";
  music = "spotify";
  calculator = "qalculate-gtk";
  bluetooth = "blueman-manager";
  sound = "pavucontrol";
  launcher = "${config.home.homeDirectory}/.config/rofi/bin/launcher";
  screenshot = "${config.home.homeDirectory}/.config/rofi/bin/screenshot";
  powermenu = "${config.home.homeDirectory}/.config/rofi/bin/powermenu";
  windowSwitcher = "${config.home.homeDirectory}/.config/rofi/bin/window";
  asusNumberpad = "systemctl --user restart asus-numberpad-driver";

  # Catppuccin Mocha palette.
  c = {
    base = "0x1e1e2e";
    mantle = "0x181825";
    crust = "0x11111b";
    surface0 = "0x313244";
    surface1 = "0x45475a";
    text = "0xcdd6f4";
    subtext0 = "0xa6adc8";
    lavender = "0xb4befe";
    mauve = "0xcba6f7";
    green = "0xa6e3a1";
    red = "0xf38ba8";
  };

  workspaceBinds = builtins.concatLists (
    builtins.genList (
      i: let
        ws = toString (i + 1);
        key = toString (i + 1);
      in [
        "${mod}, ${key}, workspace, ${ws}"
        "${mod} SHIFT, ${key}, movetoworkspace, ${ws}"
      ]
    )
    9
  );
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = null; # System module owns the Hyprland package.
    systemd.enable = true;

    settings = {
      monitor = [",preferred,auto,auto"];

      env = [
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        "GDK_BACKEND,wayland,x11,*"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_STYLE_OVERRIDE,kvantum"
        "MOZ_ENABLE_WAYLAND,1"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "OZONE_PLATFORM,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
      ];

      exec-once = [
        "nm-applet &"
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 1"
      ];

      input = {
        kb_layout = "us,cz";
        numlock_by_default = true;
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgb(${lib.removePrefix "0x" c.mauve})";
        "col.inactive_border" = "rgb(${lib.removePrefix "0x" c.surface1})";
        resize_on_border = false;
        allow_tearing = false;
        layout = "master";
      };

      decoration = {
        rounding = 0;
        shadow = {
          enabled = true;
          range = 2;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
        blur = {
          enabled = true;
          size = 2;
          passes = 2;
          special = true;
          brightness = 0.60;
          contrast = 0.75;
        };
      };

      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
          "almostLinear, 0.5, 0.5, 0.75, 1.0"
          "quick, 0.15, 0, 0.1, 1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 3.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "fadeLayersIn, 1, 1.79, almostLinear"
          "fadeLayersOut, 1, 1.39, almostLinear"
          "workspaces, 0"
        ];
      };

      master = {
        new_status = "master";
        new_on_top = false;
        mfact = 0.55;
      };

      misc = {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        focus_on_activate = true;
      };

      cursor = {
        hide_on_key_press = true;
      };

      bind =
        [
          "${mod}, Return, exec, ${terminal}"
          "${mod}, B, exec, ${browser}"
          "${mod}, E, exec, ${editor}"
          "${mod}, F, exec, ${fileManager}"
          "${mod}, M, exec, ${music}"
          "${mod}, C, exec, ${calculator}"
          "${mod}, Q, killactive,"
          "${mod}, Tab, exec, hyprctl switchxkblayout at-translated-set-2-keyboard next"

          "${mod} SHIFT, Return, exec, ${launcher}"
          "${mod} SHIFT, B, exec, ${bluetooth}"
          "${mod} SHIFT, R, exec, hyprctl reload"
          "${mod} SHIFT, Q, exec, ${powermenu}"
          "${mod} SHIFT, S, exec, ${screenshot}"
          "${mod} SHIFT, W, exec, ${windowSwitcher}"
          "${mod} SHIFT, V, exec, ${sound}"
          "${mod} SHIFT, N, exec, ${asusNumberpad}"

          "${mod} SHIFT, H, layoutmsg, mfact -0.05"
          "${mod} SHIFT, L, layoutmsg, mfact +0.05"
          "${mod} SHIFT, J, layoutmsg, swapnext"
          "${mod} SHIFT, K, layoutmsg, swapprev"

          "${mod}, H, movefocus, l"
          "${mod}, L, movefocus, r"
          "${mod}, J, movefocus, d"
          "${mod}, K, movefocus, u"
          "${mod}, Space, cyclenext"

          "${mod} SHIFT, F, fullscreen, 1"
          "${mod} CTRL SHIFT, F, togglefloating,"

          "${mod}, period, focusmonitor, +1"
          "${mod}, comma, focusmonitor, -1"
        ]
        ++ workspaceBinds;

      bindm = [
        "${mod}, mouse:272, movewindow"
        "${mod}, mouse:273, resizewindow"
      ];

      bindel = [
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86Calculator, exec, ${calculator}"
      ];

      windowrulev2 = [
        # Default opacity for all windows.
        "opacity 0.97 0.9, .*"

        # Browser full opacity.
        "opacity 1.0 0.97, class:([Ff]irefox|zen|librewolf|([Gg]oogle-)?[Cc]hrom([eium]+|[e])|[Bb]rave-browser|[Mm]icrosoft-edge|Vivaldi-stable)"

        # Media apps / image viewers.
        "opacity 1.0 1.0, class:^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|imv|org.gnome.NautilusPreviewer|com.gabm.satty)$"
        "tag +noidle, class:^(mpv|vlc)$"
        "idleinhibit always, tag:noidle"

        # Terminals keep Omarchy terminal opacity.
        "opacity 0.97 0.9, class:(Alacritty|kitty|com.mitchellh.ghostty|foot)"

        # Steam.
        "opacity 1.0 1.0, class:steam"
        "float, class:steam, title:^$"
        "size 1100 700, class:steam, title:Steam"
        "size 460 800, class:steam, title:Friends List"

        # Picture-in-picture.
        "opacity 1.0 1.0, title:(Picture.?in.?[Pp]icture)"
        "float, title:(Picture.?in.?[Pp]icture)"
        "pin, title:(Picture.?in.?[Pp]icture)"
        "size 600 338, title:(Picture.?in.?[Pp]icture)"
        "keepaspectratio, title:(Picture.?in.?[Pp]icture)"
        "bordersize 0, title:(Picture.?in.?[Pp]icture)"

        # Floating dialogs / tools.
        "float, class:^(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus|pinentry-gtk-2|pinentry)$"
        "float, title:^(Open.*Files?|Open [Ff]older.*|Save.*Files?|Save.*As|Save|All Files|.*wants to (open|save).*|Choose.*)$"
        "float, class:org.gnome.Calculator"

        # XWayland drag fix.
        "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"
      ];
    };
  };

  home.packages = with pkgs; [
    brightnessctl
    networkmanagerapplet
  ];
}
