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
      availableKernelModules = ["xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "usbhid" "sd_mod"];
      kernelModules = [];
      luks.devices."luks-9a48e6c8-6464-4bec-be68-9b92d83ddf17".device = "/dev/disk/by-uuid/9a48e6c8-6464-4bec-be68-9b92d83ddf17";
    };
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    kernelParams = ["i915.force_probe=7d55"];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b821fa08-0d79-4aa9-8b57-9f5629cdae51";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/A2B7-BAB7";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };
  };

  swapDevices = [{device = "/dev/disk/by-uuid/af8d9b14-97f5-4398-8798-380b343761b4";}];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    nvidia = {
      open = false;
      modesetting.enable = false;
    };
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };
  services.xserver.videoDrivers = [
    "modesetting"
    "fbdev"
  ];
}
