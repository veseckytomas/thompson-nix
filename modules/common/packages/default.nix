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
      # oven-sh/bun#29587 (Bun 1.4.0) makes compiled binaries reuse one content-hashed extraction of embedded native addons instead of leaking a fresh copy per Worker; drop once nixpkgs' bun is >=1.4.
      bun_1_4 = let
        version = "1.4.2";
        # stable's bun uses `mkDerivation rec`, so its `src` binds to the rec scope and ignores an overridden passthru.sources; setting src directly works on both channels.
        sources = {
          "x86_64-linux" = {
            file = "bun-linux-x64-baseline.zip";
            hash = "sha256-xngEDxT+BEDrg503y9DOTAUaMtpygGrJfeamqra/co8=";
          };
          "aarch64-linux" = {
            file = "bun-linux-aarch64.zip";
            hash = "sha256-VDKLvC2cjgyfiSxUTWbFeoO4QTnjSQnl7oF1jxrI/ac=";
          };
          "aarch64-darwin" = {
            file = "bun-darwin-aarch64.zip";
            hash = "sha256-kJh6OhbX21VtiGrD1VHnttPt8KHPQ6yu1iLoZ2vh0S8=";
          };
        };
        inherit (prev.stdenv.hostPlatform) system;
        source =
          sources.${system}
          or (throw "bun_1_4: unsupported system ${system}");
      in
        prev.bun.overrideAttrs (_old: {
          inherit version;
          src = prev.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/${source.file}";
            inherit (source) hash;
          };
        });
      # nixpkgs builds opencode from source, so compiling it with the fixed Bun stops the /tmp libopentui.so leak without waiting for opencode v2.
      opencode = prev.opencode.override {bun = final.bun_1_4;};
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
    texliveFull
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
    # LibreWolf: upstream binary release, decoupled from (unmaintained) nixpkgs
    # librewolf. Bumped by scripts/update.sh. See ./librewolf-bin.nix.
    (callPackage ./librewolf-bin.nix {})
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
    bitwarden-menu
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
    # TUI to control NixOS rebuilding (replaces scripts/main.sh). Run: `nixos-run`
    (callPackage ./nixos-run {flakePath = "/home/${username}/Git/Personal/thompson-nix";})
    # TUI to manage YubiKey OpenPGP touch policies. Run: `ykman-run`
    (callPackage ./ykman-run {})
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
    xournalpp
    motrix
    # super-productivity
    opencode
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
      pinentryPackage = inputs.nixpkgs.lib.mkForce pkgs.pinentry-gnome3;
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
