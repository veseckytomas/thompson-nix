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
    nmap

    # Lesamaj
    hugo

    # Terminal
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

    # Neovim
    ripgrep
    xclip
    codespell
    prettierd
    nodePackages.prettier
    rubyPackages.htmlbeautifier
    jq
    alejandra
    isort
    black
    rustfmt
    beautysh
    pgformatter
    taplo
    yamlfix
    htmlhint
    nodePackages.eslint
    nodePackages.jsonlint
    markdownlint-cli
    statix
    pylint
    ruff
    clippy
    shellcheck
    sqlfluff
    vale
    python312Packages.debugpy
    bashdb

    # Web browsers
    librewolf
    chromium

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
    kdePackages.kcalc
    lazygit
    lazydocker
    seahorse
    home-manager
    usbutils
    udiskie
    udisks
    plex-media-player
    postgresql
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
    firefox.enable = true;
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
      pinentryPackage = lib.mkForce pkgs.pinentry-qt;
    };
  };

  # Enable docker
  virtualisation.docker.enable = true;

  # Disable xterm
  services.xserver.excludePackages = with pkgs; [xterm];

  # Enable auto drive mounts
  services.gvfs.enable = true;
  services.udisks2.enable = true;
}
