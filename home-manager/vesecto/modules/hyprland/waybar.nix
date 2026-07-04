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
{config, ...}: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 26;
      spacing = 8;

      modules-left = [
        "image"
        "hyprland/workspaces"
        "hyprland/window"
      ];

      modules-center = [];

      modules-right = [
        "cpu"
        "memory"
        "disk"
        "hyprland/language"
        "pulseaudio"
        "battery"
        "backlight"
        "clock"
        "tray"
      ];

      image = {
        path = "${config.home.homeDirectory}/.config/backgrounds/nixos.png";
        size = 18;
        on-click = "kitty";
      };

      "hyprland/workspaces" = {
        format = "{name}";
        active-only = false;
      };

      "hyprland/window" = {
        format = "{}";
        max-length = 60;
        separate-outputs = true;
      };

      cpu = {
        format = " Cpu: {usage}%";
        tooltip = false;
      };

      memory = {
        format = " Mem: {used:0.1f}G";
        tooltip = false;
        on-click = "kitty -e btop";
      };

      disk = {
        format = "󱊞 Disk: {free}";
        path = "/";
        tooltip = false;
        on-click = "kitty -e df -h";
      };

      "hyprland/language" = {
        format = "⌨ Kbd: {}";
      };

      pulseaudio = {
        format = "{icon} Vol: {volume}%";
        format-muted = "󰖁 Muted";
        format-icons = {
          default = ["󰕿" "󰖀" "󰕾"];
        };
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} Bat: {capacity}%";
        format-icons = {
          charging = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
          default = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
        };
      };

      backlight = {
        format = "󰃠 Brightness: {percent}%";
      };

      clock = {
        format = "󰥔 {:%a, %b %d - %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
      };

      tray = {
        icon-size = 16;
        spacing = 8;
      };
    };

    style = ''
      * {
        font-family: "Hack Nerd Font Mono", monospace;
        font-size: 12px;
        min-height: 0;
      }

      window#waybar {
        background-color: #1e1e2e;
        color: #cdd6f4;
      }

      #image {
        padding: 0 8px;
      }

      #workspaces button {
        padding: 0 8px;
        color: #cdd6f4;
        background: transparent;
        border: none;
      }

      #workspaces button.active {
        color: #cba6f7;
        border-bottom: 2px solid #cba6f7;
      }

      #workspaces button:hover {
        background: rgba(205, 214, 244, 0.1);
      }

      #window {
        color: #74c7ec;
        padding: 0 8px;
      }

      #cpu {
        color: #a6e3a1;
        padding: 0 4px;
        border-bottom: 2px solid #a6e3a1;
      }

      #memory {
        color: #94e2d5;
        padding: 0 4px;
        border-bottom: 2px solid #94e2d5;
      }

      #disk {
        color: #f9e2af;
        padding: 0 4px;
        border-bottom: 2px solid #f9e2af;
      }

      #language {
        color: #f5c2e7;
        padding: 0 4px;
        border-bottom: 2px solid #f5c2e7;
      }

      #pulseaudio {
        color: #fab387;
        padding: 0 4px;
        border-bottom: 2px solid #fab387;
      }

      #battery {
        color: #f38ba8;
        padding: 0 4px;
        border-bottom: 2px solid #f38ba8;
      }

      #battery.warning {
        color: #f9e2af;
      }

      #battery.critical {
        color: #f38ba8;
      }

      #backlight {
        color: #74c7ec;
        padding: 0 4px;
        border-bottom: 2px solid #74c7ec;
      }

      #clock {
        color: #cba6f7;
        padding: 0 4px;
        border-bottom: 2px solid #cba6f7;
      }

      #tray {
        padding: 0 4px;
      }
    '';
  };
}
