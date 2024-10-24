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
      availableKernelModules = ["ufshcd_pci" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
      kernelModules = [];
      luks.devices."luks-79c0766b-82d6-4a5a-9a55-5ae45af95779".device = "/dev/disk/by-uuid/79c0766b-82d6-4a5a-9a55-5ae45af95779";
    };
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    kernelPatches = [
      {
        patch = builtins.fetchurl {
          url = "https://bugzilla.kernel.org/attachment.cgi?id=304988";
          sha256 = "sha256:1jilgcs7h6rwrc9dzskq0d8lw8hhwncrajlbjcs2mcg8krl05jpc";
        };
      }
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/0202a1b4-da18-4e47-9c93-e27d027217c1";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/9682-DDB5";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/b4741a51-9d2f-4653-9c1f-fea1399daa67";}
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
