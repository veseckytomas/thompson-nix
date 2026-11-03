#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  lib,
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
    (_: prev: {
      openldap = prev.openldap.overrideAttrs (old: {
        doCheck = false;
      });
      # read_key returned buffer.value, whose NUL-terminated semantics truncate a keyring's binary serial array whenever a serial contains a zero byte (NixOS/nixpkgs#576985).
      udiskie = prev.udiskie.overrideAttrs (old: {
        postPatch =
          (old.postPatch or "")
          + ''
            substituteInPlace udiskie/keyutils.py \
              --replace-fail 'return buffer.value' 'return buffer.raw[:ret]'
          '';
      });
      # swt 4.34 strips -Werror in its own postPatch, so the -Wno-error override this overlay used to carry is gone.
      inherit (pkgs-stable) swt;
      # Upstream glues "--reruns 3" into one argv, which structuredAttrs no longer word-splits, so pytest collects 0 tests and exits 5 (NixOS/nixpkgs#579425).
      pythonPackagesExtensions =
        prev.pythonPackagesExtensions
        ++ [
          (_: pyPrev: {
            qtile-extras = pyPrev.qtile-extras.overridePythonAttrs (_: {
              pytestFlags = ["--reruns" "3" "--reruns-delay" "5"];
            });
          })
        ];
    })
  ];

  # Guards the dropped bun_1_4 overlay: below 1.4, opencode leaks a libopentui.so copy
  # per Worker into /tmp (oven-sh/bun#29587), which that overlay existed to prevent.
  assertions = [
    {
      assertion = lib.versionAtLeast pkgs.bun.version "1.4";
      message = "nixpkgs' bun is ${pkgs.bun.version}, below the 1.4 that fixes oven-sh/bun#29587; restore a bun >=1.4 overlay for opencode.";
    }
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
    # smartd already monitors the NVMe through VMD, but without these the health it sees is unreadable by hand.
    smartmontools
    nvme-cli
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
    # opencode: removed — nixpkgs package tracked 2.2.1 which migrated the shared
    # ~/.local/share/opencode/opencode.db and broke 1.19. Install/check via
    # home-manager/vesecto/modules/opencode instead.
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
