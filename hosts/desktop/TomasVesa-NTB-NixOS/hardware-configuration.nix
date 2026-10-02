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
    # Intel erratum MTL016 strands an NVMe completion behind VMD, and io_timeout is how long the kernel waits before polling it out, so it is recovery latency rather than grace for the drive.
    kernelParams = ["i915.force_probe=7d55" "nvme_core.default_ps_max_latency_us=0" "nvme_core.io_timeout=10"];
    resumeDevice = "/dev/dm-0";
    # zstd zram returns 3.76x, so paging anonymous memory there beats evicting page cache the working set still needs.
    kernel.sysctl = {
      "vm.swappiness" = 150;
      "vm.vfs_cache_pressure" = 50;
      # zram is random-access, so reading neighbour pages on a fault is wasted decompression.
      "vm.page-cluster" = 0;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b821fa08-0d79-4aa9-8b57-9f5629cdae51";
      fsType = "ext4";
      # systemd fails a mount job after 90s and never retries it, so the ceiling must outlast a burst of MTL016 strandings.
      options = ["x-systemd.mount-timeout=300"];
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
