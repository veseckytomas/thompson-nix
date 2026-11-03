#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  pkgs,
  lib,
  ...
}: {
  security = {
    rtkit.enable = true;
    sudo.enable = true;

    # Enable Yubikey support
    pam.u2f = {
      enable = lib.mkDefault true;
      settings.cue = true;
      control = lib.mkDefault "required";
    };
  };

  # YubiKey smartcard (CCID) support.
  # pcscd is the PC/SC daemon that lets `ykman` and gpg's OpenPGP applet talk to
  # the card; yubikey-manager provides the `ykman` CLI.
  services.pcscd.enable = true;
  environment.systemPackages = [pkgs.yubikey-manager];

  # Desktop popup while the YubiKey blocks on a touch; needs a running notifier (swaync/dunst).
  programs.yubikey-touch-detector.enable = true;

  security.polkit.enable = true;
  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
