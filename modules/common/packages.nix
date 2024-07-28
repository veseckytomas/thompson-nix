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
    atuin
    firefox
    kitty
    ansible
    asciidoc
    jetbrains.datagrip
    bat
    bitwarden
    curl
    discord
    docker-compose
    doxygen
    evince
    eza
    fd
    fzf
    git
    git-crypt
    gzip
    htop
    librewolf
    qbittorrent
    gotop
    ntfs3g
    obsidian
    steam
    starship
    gnutar
    xfce.thunar
    tmux
    traceroute
    unzip
    vscodium
    zip
    zoxide
    postman
    teams-for-linux
    protonvpn-gui
    clang
    cmake
    cppcheck
    gnumake
    cargo
    keepass
    lua
    luarocks
    ripgrep
    xclip
    nodejs
    python3
    shellcheck
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
    codeium
    jdk
    swt
    wget
    gcc
    texlive.combined.scheme-full
    seahorse
    dig
    yazi



    # Chrome
    google-chrome
    chromium
    # alacritty
    hugo
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
