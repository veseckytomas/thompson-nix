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
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Shell
    atuin
    bat
    curl
    eza
    fd
    fzf
    gzip
    htop
    gotop
    starship
    gnutar
    tmux
    traceroute
    unzip
    zip
    zoxide
    gcc
    wget
    texlive.combined.scheme-full
    dig
    yazi

    # Lesamaj
    hugo

    # Terminal emulator
    kitty

    # Programming
    ansible
    asciidoc
    jetbrains.datagrip
    doxygen
    postman
    clang
    clang-tools
    cmake
    cppcheck
    gnumake
    cargo
    shellcheck
    nodejs
    python3
    pandoc

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
    inputs.zen-browser.packages."x86_64-linux".specific

    # Text editors
    vscodium

    # libreoffice
    libreoffice
    hunspell
    hunspellDicts.cs-cz
    hunspellDicts.en-us

    # Other
    bitwarden
    discord
    evince
    git
    git-crypt
    qbittorrent
    ntfs3g
    obsidian
    teams-for-linux
    protonvpn-gui
    protonvpn-cli
    spotify
    whatsapp-for-linux
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
    postgresql
    kodi
    stremio
    qalculate-gtk
  ];

  # Install nerdfonts
  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["Hack"];})
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
  };
}
