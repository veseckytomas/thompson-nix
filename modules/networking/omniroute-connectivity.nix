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
# Pairs with the HM omniroute plugin: the gateway's circuit breakers live in process memory,
# so only a restart clears a breaker latched while the laptop had no link at all.
{
  pkgs,
  username,
  ...
}: let
  # user@.service owns the gateway, so the root dispatcher reaches it through the user manager.
  restartHook = pkgs.writeShellScript "omniroute-restart-on-connectivity" ''
    [ "$2" = "up" ] || exit 0

    uid=$(${pkgs.coreutils}/bin/id -u ${username}) || exit 0

    # systemctl --machine= hardcodes -pPAMName=login, whose session stack auto_starts a passwordless gnome-keyring that then rejects the real login's password; reach the user bus directly instead.
    export XDG_RUNTIME_DIR="/run/user/$uid"
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus"
    [ -S "/run/user/$uid/bus" ] || exit 0

    # setpriv drops to the user without PAM, so no pam_u2f Yubikey touch on every network event.
    as_user="${pkgs.util-linux}/bin/setpriv --reuid=$uid --regid=$uid --init-groups"

    # Breaker state is only worth clearing once the gateway is actually running.
    $as_user ${pkgs.systemd}/bin/systemctl --user is-active --quiet omniroute.service || exit 0

    $as_user ${pkgs.systemd}/bin/systemctl --user restart omniroute.service
  '';
in {
  networking.networkmanager.dispatcherScripts = [
    {
      source = restartHook;
      type = "basic";
    }
  ];
}
