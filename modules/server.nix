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
  inputs,
  pkgs,
  lib,
  username,
  ...
}: {
  imports = [
    inputs.home-manager-stable.nixosModules.home-manager
  ];
  # Home-manager
  home-manager = {
    extraSpecialArgs = {inherit inputs username;};
    users.${username} = import ../home-manager/${username}-server;
  };

  # Bootloader
  boot.loader.grub.enable = lib.mkDefault true;
  boot.loader.grub.device = lib.mkDefault "/dev/sda";

  nix = {
    # Enable nix flakes
    settings.experimental-features = ["nix-command" "flakes"];

    # Garbage collection
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
    optimise = {
      automatic = true;
      dates = ["weekly"];
    };
  };

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--no-write-lock-file"
      "-L"
    ];
    dates = "*:0/10:00";
  };

  # Networking
  networking.networkmanager.enable = true;

  # Timezone
  time.timeZone = "Europe/Prague";

  # Packages
  environment.systemPackages = with pkgs; [
    git
    trash-cli
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
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG8bYPFdj4hAx3gqCyMf5JPZXmBa7i5i63Qju0/rthOa openpgp:0x5D1FEA31"
    ];
  };

  services = {
    # Enable QEMU Guest Agent
    qemuGuest.enable = lib.mkDefault true;

    # Enable the OpenSSH daemon.
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    # Enable keyring
    gnome.gnome-keyring.enable = true;
  };

  # Set systemd timer
  # systemd = {
  #   services.rebuild = {
  #     script = ''
  #       cd /thompson-nix
  #       git pull
  #     '';
  #     script = ''
  #       cd /thompson-nix
  #       ${pkgs-stable.git}/bin/git pull
  #       ${pkgs-stable.nixos-rebuild}/bin/nixos-rebuild switch --flake .# --no-write-lock-file --cores 1 -j 1
  #       if [ "$(uname -m)" = "aarch64" ]
  #       then
  #         ${pkgs-stable.su}/bin/su vesecto -c "cd /home/vesecto/thompson-nix && ${pkgs-stable.git}/bin/git pull && ${pkgs-stable.home-manager}/bin/home-manager switch --flake .#vesecto-server-arm --no-write-lock-file -j 1 --cores 1 && ${pkgs-stable.home-manager}/bin/home-manager expire-generations -14days"
  #       else
  #         ${pkgs-stable.su}/bin/su vesecto -c "cd /home/vesecto/thompson-nix && ${pkgs-stable.git}/bin/git pull && ${pkgs-stable.home-manager}/bin/home-manager switch --flake .#vesecto-server --no-write-lock-file -j 1 --cores 1 && ${pkgs-stable.home-manager}/bin/home-manager expire-generations -14days"
  #       fi
  #     '';
  #     startAt = "daily";
  #     serviceConfig.Type = "oneshot";
  #   };
  # };

  # Firewall open ports
  networking.firewall.allowedTCPPorts = [22];
}
