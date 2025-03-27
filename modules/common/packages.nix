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
  username,
  system,
  ...
}: {
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List of packages
  environment.systemPackages = with pkgs; [
    # Shell
    (callPackage ./packages/2048.nix {inherit inputs;})
    curl
    gzip
    gnutar
    pigz
    gcc
    wget
    texlive.combined.scheme-full

    # Terminal emulator
    kitty

    # Programming
    jetbrains.datagrip
    postman

    # Docker
    docker-compose

    # DWH
    keepass
    jdk
    swt
    steam-run

    # Web browsers
    librewolf
    chromium
    firefox
    inputs.zen-browser.packages.${system}.specific

    # Text editors
    vscodium

    # libreoffice
    libreoffice
    hunspell
    hunspellDicts.cs-cz
    hunspellDicts.en-us

    # Other
    nomacs
    bitwarden
    discord
    evince
    git
    git-crypt
    pre-commit
    qbittorrent
    ntfs3g
    obsidian
    protonvpn-gui
    protonvpn-cli
    spotify
    gimp
    thunderbird
    telegram-desktop
    vlc
    wireshark
    lazygit
    lazydocker
    seahorse
    home-manager
    usbutils
    udiskie
    udisks
    plex-media-player
    kodi
    stremio
    qalculate-gtk
    signal-desktop
    whatsapp-for-linux
    alsa-utils
    pavucontrol
    teams-for-linux
    xournalpp
    motrix
  ];

  # Install nerdfonts
  fonts.packages = [
    pkgs.nerd-fonts.hack
  ];

  programs = {
    # Enable neovim and set as default editor
    neovim = {
      enable = true;
      defaultEditor = true;
    };

    # Enable web browsers for developments
    chromium.enable = true;

    # Enable zsh
    zsh.enable = true;

    # Enable thunar
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-volman
      ];
    };

    # Enable nh
    nh = {
      enable = true;
      flake = "/home/${username}/Git/Personal/thompson-nix";
    };

    # Enable gnupg
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = inputs.nixpkgs.lib.mkForce pkgs.pinentry-qt;
    };
  };

  # Enable docker
  virtualisation.docker.enable = true;

  services = {
    # Disable xterm
    xserver.excludePackages = with pkgs; [xterm];

    # Enable auto drive mounts
    gvfs.enable = true;
    udisks2.enable = true;

    # Enable ollama
    ollama.enable = true;
  };
}
