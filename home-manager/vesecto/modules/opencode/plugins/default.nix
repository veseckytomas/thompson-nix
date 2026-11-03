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
{...}: {
  imports = [
    ./cache-control-cap
    ./claude-token-sync
    ./graphify
    ./local-skills
    ./oh-my-openagent
    ./omniroute
    ./session-list-all
    ./system-message-hoist
    ./gsd-sdk.nix
    ./gsd.nix
    ./caveman.nix
    ./superpowers.nix
    ./mattpocock.nix
  ];
}
