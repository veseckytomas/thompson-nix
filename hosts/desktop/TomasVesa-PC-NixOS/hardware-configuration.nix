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
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = ["xhci_pci" "ahci" "usbhid" "uas" "sd_mod"];
      kernelModules = [];
      luks.devices."luks-26d5311f-4199-49cb-b93c-048d5b9305b7".device = "/dev/disk/by-uuid/26d5311f-4199-49cb-b93c-048d5b9305b7";
    };
    kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
    supportedFilesystems = ["ntfs"];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/23f7ff37-986a-4da5-b305-e5c9a54488ec";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/433D-441E";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
    "/mnt/hdd" = {
      device = "/dev/disk/by-uuid/d2a85e35-383a-4de6-b930-381cfe199b92";
      fsType = "ext4";
    };
    "/mnt/hdd_win" = {
      device = "/dev/disk/by-uuid/863EE1E93EE1D1EB";
      fsType = "ntfs-3g";
      options = ["defaults" "uid=1000" "fmask=0022" "dmask=0022"];
    };
    # "/mnt/ssd_win" = {
    #   device = "/dev/disk/by-uuid/66743EE1743EB421";
    #   fsType = "ntfs-3g";
    #   options = ["defaults" "uid=1000" "fmask=0022" "dmask=0022"];
    # };
  };

  swapDevices = [{device = "/dev/disk/by-uuid/ce46aa64-ec69-44d2-9a50-66631a957d3d";}];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      open = false;
      # modesetting.enable = true;
    };
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };
  # services.xserver = {
  #   enable = true;
  #   videoDrivers = [
  #     "nvidia"
  #     "modesetting"
  #     "fbdev"
  #   ];
  # };
}
