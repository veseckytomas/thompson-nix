{ config, pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    alacritty
    ansible
    asciidoc
    bat
    bitwarden
    blueman
    bluez
    cargo
    clang
    cmake
    cppcheck
    curl
    docker-compose
    doxygen
    evince
    eza
    fd
    feh
    fzf
    git
    git-crypt
    gzip
    htop
    librewolf
    lua
    luarocks
    gnumake
    nodejs
    ntfs3g
    obsidian
    python3
    ripgrep
    rofi
    shellcheck
    steam
    starship
    stow
    gnutar
    xfce.thunar
    tmux
    traceroute
    unzip
    virtualbox
    vscodium
    xclip
    zip
    zoxide
    clion
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" ]; })
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };
  programs.zsh.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
