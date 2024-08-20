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
  ...
}: {
  # Load OpenGL
  hardware.opengl = {
    enable = true;
    # driSupport = true;
    driSupport32Bit = true;
  };

  # Load GPU Drivers
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia.modesetting.enable = true;

  # Enable steam
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  # Other packages
  environment.systemPackages = with pkgs; [
    mangohud
    protonup
    lutris
    heroic
    bottles
  ];

  # Optimizations
  programs.gamemode.enable = true;
}
