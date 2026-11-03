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
  config,
  ...
}: let
  port = 4096;
  url = "http://127.0.0.1:${toString port}";
in {
  # One shared headless backend so every `oc` client reuses a single server process instead of each spawning its own (~1GB) — bound to loopback, never started at boot.
  systemd.user.services.opencode-server = {
    Unit = {
      Description = "Shared headless opencode backend (loopback only)";
      Documentation = ["https://opencode.ai/docs/server/"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${config.programs.opencode.package}/bin/opencode serve --hostname 127.0.0.1 --port ${toString port}";
      # A --user service does not inherit the login shell env; give opencode what it needs to find its runtime deps and provider tooling.
      Environment = [
        "PATH=${config.home.homeDirectory}/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/run/wrappers/bin"
        "OMO_CODEGRAPH_BIN=${config.home.sessionVariables.OMO_CODEGRAPH_BIN}"
        "LANG=en_US.UTF-8"
        "XDG_CONFIG_HOME=${config.xdg.configHome}"
        "XDG_DATA_HOME=${config.xdg.dataHome}"
        "XDG_STATE_HOME=${config.xdg.stateHome}"
        "XDG_CACHE_HOME=${config.xdg.cacheHome}"
      ];
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStopSec = "20s";
    };
    # Deliberately no Install.WantedBy: the unit stays inert until `oc` starts it on first use since boot.
  };

  # `oc`: start the shared backend on first use (idempotent), wait until it is listening, then attach a client scoped to $PWD.
  programs.zsh.initContent = lib.mkAfter ''
    unalias oc 2>/dev/null
    function oc() {
      systemctl --user start opencode-server.service || return 1
      local i
      for i in {1..120}; do
        ${pkgs.curl}/bin/curl -fsS ${url}/global/health >/dev/null 2>&1 && break
        sleep 0.5
      done
      if ! ${pkgs.curl}/bin/curl -fsS ${url}/global/health >/dev/null 2>&1; then
        echo "oc: opencode-server not ready (check: journalctl --user -u opencode-server -e)" >&2
        return 1
      fi
      local dir="$PWD"
      if [[ -n "$1" && -d "$1" ]]; then dir="$1"; shift; fi
      opencode attach ${url} --dir "$dir" "$@"
    }
  '';
}
