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
{pkgs-stable, ...}: {
  # Virt-manager
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      package = pkgs-stable.libvirt;
      qemu.package = pkgs-stable.qemu_full;
    };
  };
  programs.virt-manager = {
    enable = true;
    package = pkgs-stable.virt-manager;
  };
  environment.systemPackages = with pkgs-stable; [
    virtiofsd
    qemu_full
  ];
}
