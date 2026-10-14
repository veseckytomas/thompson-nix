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

    # Breaker state is only worth clearing once the gateway is actually running.
    ${pkgs.systemd}/bin/systemctl --machine=${username}@.host --user is-active --quiet omniroute.service || exit 0

    ${pkgs.systemd}/bin/systemctl --machine=${username}@.host --user restart omniroute.service
  '';
in {
  networking.networkmanager.dispatcherScripts = [
    {
      source = restartHook;
      type = "basic";
    }
  ];
}
