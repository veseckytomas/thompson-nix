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
  pkgs-stable,
  inputs,
  ...
}: {
  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Networking
  networking.networkmanager.enable = true;

  # Timezone
  time.timeZone = "Europe/Prague";

  # Packages
  environment.systemPackages = with pkgs-stable; [
    postgresql
    git
    docker-compose
    wget
    tmux
    htop
    gzip
    curl
    gnutar
  ];
  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    zsh.enable = true;
  };

  # Set locale
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT = "cs_CZ.UTF-8";
    LC_MONETARY = "cs_CZ.UTF-8";
    LC_NAME = "cs_CZ.UTF-8";
    LC_NUMERIC = "cs_CZ.UTF-8";
    LC_PAPER = "cs_CZ.UTF-8";
    LC_TELEPHONE = "cs_CZ.UTF-8";
    LC_TIME = "cs_CZ.UTF-8";
  };

  # Define users
  users.users.vesecto = {
    isNormalUser = true;
    description = "Tomas Vesecky";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs-stable.zsh;
  };

  services = {
    # Enable QEMU Guest Agent
    qemuGuest.enable = true;

    # Set cron
    cron = {
      enable = true;
      systemCronJobs = [
        "0 0 * * *  root  ~/home/vesecto/thompson-nix/scripts/rebuild-server.sh"
      ];
    };
    # Enable the OpenSSH daemon.
    openssh.enable = true;
  };

  # Firewall open ports
  networking.firewall.allowedTCPPorts = [22];

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "01:00";
    options = "--delete-older-than 10d";
  };
  nix.optimise = {
    automatic = true;
    dates = ["02:00"];
  };


  # System version
  system.stateVersion = "24.05";
}
