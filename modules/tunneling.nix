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
  imports = [
    ./audio
    ./bootLoaders
    ./loginManagers
    ./windowManagers/i3.nix
    ./common/common.nix
    ./common/locale.nix
    ./common/notebook.nix
    ./common/users.nix
  ];
  environment.systemPackages = with pkgs; [
    kitty
    python3
    git
    ntfs3g
  ];

  fonts.packages = with pkgs; [
    (nerdfonts.override {fonts = ["Hack"];})
  ];
  programs = {
    # Enable neovim and set as default editor
    neovim = {
      enable = true;
      defaultEditor = true;
    };
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
  services = {
    # Disable xterm
    xserver.excludePackages = with pkgs; [xterm];

    # Enable auto drive mounts
    gvfs.enable = true;
    udisks2.enable = true;
  };
}
