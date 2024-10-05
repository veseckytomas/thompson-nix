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
{pkgs-stable, ...}: {
  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  nix = {
    # Enable nix flakes
    settings.experimental-features = ["nix-command" "flakes"];

    # Garbage collection
    gc = {
      automatic = true;
      dates = "01:00";
      options = "--delete-older-than 10d";
    };
    optimise = {
      automatic = true;
      dates = ["02:00"];
    };
  };

  # Networking
  networking.networkmanager.enable = true;

  # Timezone
  time.timeZone = "Europe/Prague";

  # Packages
  environment.systemPackages = with pkgs-stable; [
    git
    wget
    tmux
    htop
    gzip
    curl
    gnutar
    home-manager
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
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIF72lKNXtnCRS7Pb9+oB8Urusf9QEJmw1XEOhLQjxbenAAAABHNzaDo= Primary Key"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIO+xfsaB1PekrdJ6Zmt8ByvScyFy51hF2ZKRU9Glh8phAAAABHNzaDo= Secondary Key"
    ];
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
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };

  # Firewall open ports
  networking.firewall.allowedTCPPorts = [22];

  # System version
  system.stateVersion = "24.05";
}
