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
{pkgs, ...}: {
  # Load OpenGL
  hardware.graphics = {
    enable = true;
    # driSupport = true;
    enable32Bit = true;
  };

  # Load GPU Drivers
  services.xserver.videoDrivers = [
    "nvidia"
    "modesetting"
    "fbdev"
  ];
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
    libgpg-error
    libxml2
    freetype
    gnutls
    openldap
    SDL2
    sqlite
    xml2
  ];
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;
  environment.variables = {
    GPERF32_PATH = "${pkgs.pkgsi686Linux.gperftools}";
  };

  # Optimizations
  # programs.gamemode.enable = true;
}
