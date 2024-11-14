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

  boot.initrd.availableKernelModules = ["ufshcd_pci" "xhci_pci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];

  boot.kernelPatches = [
    {
      patch = builtins.fetchurl {
        url = "https://bugzilla.kernel.org/attachment.cgi?id=304988";
        sha256 = "sha256:1jilgcs7h6rwrc9dzskq0d8lw8hhwncrajlbjcs2mcg8krl05jpc";
      };
    }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/0202a1b4-da18-4e47-9c93-e27d027217c1";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-79c0766b-82d6-4a5a-9a55-5ae45af95779".device = "/dev/disk/by-uuid/79c0766b-82d6-4a5a-9a55-5ae45af95779";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9682-DDB5";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/22d4cbff-54d8-415e-90b8-bce4f4395a1e";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
