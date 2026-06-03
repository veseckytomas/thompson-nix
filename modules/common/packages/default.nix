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
  pkgs-stable,
  inputs,
  username,
  ...
}: {
  # Allow unfree packages
  nixpkgs.config = {
    allowUnfree = true;
  };

  # Global overlays
  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (old: {
        doCheck = false;
      });
      swt = pkgs-stable.swt.overrideAttrs (old: {
        NIX_CFLAGS_COMPILE = toString (old.env.NIX_CFLAGS_COMPILE or "") + " -Wno-error";
      });
    })
  ];

  # List of packages
  environment.systemPackages = with pkgs; [
    # Shell
    curl
    gzip
    gnutar
    pigz
    gcc
    wget
    texlive.combined.scheme-full
    typst

    # Terminal emulator
    kitty

    # Programming
    jetbrains.datagrip

    # DWH
    keepass
    jdk
    swt
    steam-run

    # Web browsers
    librewolf
    chromium
    firefox

    # Text editors
    vscodium

    # libreoffice
    pkgs-stable.libreoffice
    pkgs-stable.hunspell
    pkgs-stable.hunspellDicts.cs-cz
    pkgs-stable.hunspellDicts.en-us

    # Task management
    # taskwarrior3
    # taskwarrior-tui
    # (taskwarrior-tui.overrideAttrs
    #   (old: {
    #     src = inputs.taskwarrior-tui;
    #     cargoDeps = pkgs.rustPlatform.importCargoLock {
    #       lockFile = inputs.taskwarrior-tui + "/Cargo.lock";
    #       allowBuiltinFetchGit = true;
    #     };
    #   }))

    # Other
    nomacs
    # bitwarden-desktop
    bitwarden-cli
    discord
    evince
    kdePackages.okular
    git
    git-crypt
    pre-commit
    qbittorrent
    ntfs3g
    obsidian
    proton-vpn
    proton-vpn-cli
    spotify
    gimp
    thunderbird
    telegram-desktop
    vlc
    lazygit
    home-manager
    usbutils
    udiskie
    udisks
    # plex-desktop
    # stremio
    qalculate-gtk
    signal-desktop
    karere
    alsa-utils
    pavucontrol
    teams-for-linux
    xournalpp
    motrix
    # super-productivity
    codex
    cursor-cli
    claude-code
    gemini-cli
    opencode
    github-copilot-cli
    localsend
    anki-bin
    glab
    croc

    dust
    fselect
    bacon
    mprocs
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
      plugins = with pkgs; [
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
      pinentryPackage = inputs.nixpkgs.lib.mkForce pkgs.pinentry-gtk2;
    };

    nano.enable = false;
  };

  services = {
    # Disable xterm
    xserver.excludePackages = with pkgs; [xterm];

    # Enable auto drive mounts
    gvfs.enable = true;
    udisks2.enable = true;

    # Enable ollama
    # ollama.enable = true;
    # open-webui = {
    #   enable = true;
    #   port = 8181;
    # };
  };
}
