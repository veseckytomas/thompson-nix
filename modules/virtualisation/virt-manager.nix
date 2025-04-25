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
{pkgs, ...}: {
  # Virt-manager
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd.enable = true;
  };
  programs.virt-manager.enable = true;
  environment.systemPackages = with pkgs; [
    virtiofsd
    qemu_full
  ];
}
