{ config, pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    atuin
    google-chrome
    firefox
    alacritty
    ansible
    asciidoc
    jetbrains.datagrip
    bat
    bitwarden
    cargo
    clang
    cmake
    cppcheck
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
    # hugo
    keepass
    librewolf
    lua
    luarocks
    gnumake
    qbittorrent
    gotop
    nodejs
    ntfs3g
    obsidian
    python3
    ripgrep
    shellcheck
    steam
    starship
    stow
    gnutar
    xfce.thunar
    tmux
    traceroute
    unzip
    # virtualbox
    vscodium
    xclip
    zip
    zoxide
    postman
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
  ];

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
  };

  # Disable xterm
  services.xserver.excludePackages = [ pkgs.xterm ];
}
