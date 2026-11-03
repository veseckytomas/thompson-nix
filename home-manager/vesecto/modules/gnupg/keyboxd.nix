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
{pkgs, ...}: let
  tools = pkgs.callPackage ./tools.nix {};
in {
  # Without a unit, keyboxd is an autostarted orphan in a transient scope: it dies by cgroup
  # SIGKILL, so its atexit handler never releases the pubring.db dotlock.
  systemd.user.sockets.keyboxd = {
    Unit.Description = "GnuPG public key database daemon socket";
    Socket = {
      ListenStream = "%t/gnupg/S.keyboxd";
      FileDescriptorName = "std";
      SocketMode = "0600";
      DirectoryMode = "0700";
    };
    Install.WantedBy = ["sockets.target"];
  };

  systemd.user.services.keyboxd = {
    Unit = {
      Description = "GnuPG public key database daemon";
      Requires = ["keyboxd.socket"];
      After = ["keyboxd.socket"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.gnupg}/libexec/keyboxd --supervised";
      ExecReload = "${pkgs.gnupg}/bin/gpgconf --reload keyboxd";
      # Belt for a SIGKILL after TimeoutStopSec, when the atexit handler cannot run.
      ExecStopPost = "${tools.keybox-sweep}/bin/keybox-sweep";
      TimeoutStopSec = "20";
    };
  };
}
