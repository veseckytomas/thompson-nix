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
      availableKernelModules = ["nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc"];
      kernelModules = [];
      luks.devices."luks-1aee5a77-9651-4eaa-8dad-9a689110b4e7".device = "/dev/disk/by-uuid/1aee5a77-9651-4eaa-8dad-9a689110b4e7";
    };
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/a3f956be-93b7-41ec-8ef7-8c4a7f508971";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/B2D9-70C9";
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/48a65e01-3f43-4b24-94e9-0e7905a86bef";}
  ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
