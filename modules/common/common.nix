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
  hostname,
  pkgs,
  pkgs-hplip,
  lib,
  ...
}: {
  nix.settings = {
    # Enable nix flakes
    experimental-features = ["nix-command" "flakes"];

    # Set vesecto as trusted user
    trusted-users = ["root" "vesecto"];
  };

  # Set hostname
  networking.hostName = "${hostname}";

  boot = {
    # Set kernel
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Its "D! /tmp" rule collides with the aging rule below and loses silently; both are merged there instead.
    tmp.cleanOnBoot = false;
  };

  # Bun <1.4 re-extracts a ~14MB native addon into /tmp per Worker and never unlinks it (oven-sh/bun#29585); one rule, since systemd-tmpfiles honours only one per path: D! wipes at boot, 1d ages the rest.
  systemd.tmpfiles.rules = ["D! /tmp 1777 root root 1d"];

  # nixpkgs#554650: ProtectSystem=strict blocks avahi's own stale-pidfile cleanup, so one unclean stop breaks every later start (and fails resolvconf via its kill -HUP hook); "+" runs this unsandboxed.
  systemd.services.avahi-daemon.serviceConfig.ExecStartPre = "+${pkgs.coreutils}/bin/rm -f /run/avahi-daemon/pid";

  services = {
    # Enable Gnome keyring
    gnome.gnome-keyring.enable = true;

    # Printing
    printing = {
      enable = true;
      drivers = [
        # hplip 3.26.4 breaks on unstable; use pinned fixed rev. Remove with nixpkgs-hplip input when channel catches up.
        pkgs-hplip.hplipWithPlugin
      ];
    };
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      # nixpkgs' ipp-usb.nix still sets the deprecated publish.* options; force-null them and replicate via settings (behavior identical).
      publish = {
        enable = lib.mkForce null;
        userServices = lib.mkForce null;
      };
      settings.publish = {
        disable-publishing = false;
        disable-user-service-publishing = false;
        publish-addresses = true;
      };
    };
    ipp-usb.enable = true;

    libinput.enable = true;
    fstrim.enable = true;
    gvfs.enable = true;
    tumbler.enable = true;

    smartd = {
      enable = true;
      autodetect = true;
    };
  };

  # Set your time zone
  time.timeZone = "Europe/Prague";

  # Enable zsh completion for system packages
  environment.pathsToLink = ["/share/zsh"];

  # System version
  system.stateVersion = "26.05";
}
