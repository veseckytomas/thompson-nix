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
  pkgs,
  inputs,
  ...
}: {
  services = {
    xserver = {
      enable = true;
      # displayManager.setupCommands = ''
      #   connected_display_names=$(xrandr | grep " connected" | cut -d ' ' -f1 | tail -n+2)
      #   primary_display=$(xrandr | grep " connected" | cut -d ' ' -f1 | head -n1)
      #   for display in $connected_display_names; do
      #     xrandr --output $display --auto --same-as $primary_display
      #   done
      # '';
    };
    displayManager = {
      defaultSession = "qtile";
      sddm = {
        enable = true;
        autoNumlock = true;
        # theme = "${import ./sugar-dark {inherit pkgs inputs;}}";
      };
    };
  };
  catppuccin.sddm = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
    font = "Hack Nerd Font";
    userIcon = false;
    clockEnabled = true;
    background = "${import ./background {inherit pkgs inputs;}}/sddm_bg.png";
  };
  environment.systemPackages = with pkgs; [
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
  ];
}
