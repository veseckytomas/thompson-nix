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

{ config, pkgs, lib, ... }:

{
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

    # Lesamaj
    hugo

    # Teminal
    kitty

    # Programming
    ansible
    asciidoc
    jetbrains.datagrip
    doxygen
    postman
    clang
    cmake
    cppcheck
    gnumake
    cargo
    shellcheck
    nodejs
    python3

    # Docker
    docker-compose

    # DWH
    keepass
    jdk
    swt

    # Neovim
    lua
    luarocks
    ripgrep
    xclip
    codeium

    # Web browsers
    librewolf
    google-chrome
    chromium

    # Text editors
    vscodium

    # Other
    bitwarden
    discord
    evince
    git
    git-crypt
    qbittorrent
    ntfs3g
    obsidian
    xfce.thunar
    teams-for-linux
    protonvpn-gui
    protonvpn-cli
    spotify
    whatsapp-for-linux
    gimp
    libreoffice
    thunderbird
    telegram-desktop
    vlc
    wireshark
    kdePackages.kcalc
    lazygit
    lazydocker
    seahorse

    # alacritty
    # firefox
  ];

  # Install flatpak
  xdg.portal.enable = true;
  services.flatpak.enable = true;

  # Install nerdfonts
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" ]; })
  ];

  # Enable neovim and set as default editor
  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  # Enable web browsers for developments
  programs.firefox.enable = true;
  programs.chromium.enable = true;

  # Enable zsh
  programs.zsh.enable = true;

  # Enable docker
  virtualisation.docker.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = lib.mkForce pkgs.pinentry-qt;
    # pinentryPackage = lib.mkForce pkgs.pinentry-gtk2;
  };

  # Disable xterm
  services.xserver.excludePackages = [ pkgs.xterm ];
}
