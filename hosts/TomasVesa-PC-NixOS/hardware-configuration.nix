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
      availableKernelModules = ["xhci_pci" "ahci" "usbhid" "uas" "sd_mod"];
      kernelModules = [];
      luks.devices."luks-0e27fe0a-b2e3-4df6-822b-af72783d54d2".device = "/dev/disk/by-uuid/0e27fe0a-b2e3-4df6-822b-af72783d54d2";
    };
    supportedFilesystems = ["ntfs"];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f491badc-a573-4746-a242-3c38599dc978";
    fsType = "ext4";
  };

  fileSystems = {
    "/boot" = {
      device = "/dev/disk/by-uuid/29DE-7728";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
    "/mnt/hdd" = {
      device = "/dev/disk/by-uuid/d2a85e35-383a-4de6-b930-381cfe199b92";
      fsType = "ext4";
    };
    # "/mnt/hdd_win" = {
    #   # device = "/dev/disk/by-uuid/863EE1E93EE1D1EB";
    #   device = "/dev/sdb1";
    #   fsType = "ntfs-3g";
    #   options = ["rw" "uid=theUidOfYourUser"];
    # };
    # "/mnt/ssd_win" = {
    #   # device = "/dev/disk/by-uuid/B490644890641362";
    #   device = "/dev/sdc2";
    #   fsType = "ntfs-3g";
    #   options = ["rw" "uid=theUidOfYourUser"];
    # };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/ff4ce559-ffcb-4af6-8e13-f2d428af6a61";}
  ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
