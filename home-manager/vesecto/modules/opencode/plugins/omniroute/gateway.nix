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
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.opencodePlugins.omniroute;

  # Version pin lives in the shared npm-plugins.json (bumped by nixos-run update).
  npmPlugins = builtins.fromJSON (builtins.readFile ../npm-plugins.json);
  version = npmPlugins.omniroute;

  dataDir = "${config.xdg.dataHome}/omniroute";
  versionDir = "${dataDir}/omniroute@${version}";
  # Omniroute's entry point relative to the npm-installed node_modules tree.
  omnirouteMjs = "${versionDir}/node_modules/omniroute/bin/omniroute.mjs";

  provisionScript = pkgs.writeShellApplication {
    name = "omniroute-provision-combos";
    runtimeInputs = [pkgs.curl pkgs.jq];
    text = builtins.readFile ./provision-combos.sh;
  };

  gnupgTools = pkgs.callPackage ../../../gnupg/tools.nix {};

  # Admin API token, GPG-encrypted, lives OUTSIDE the repo (manually placed per
  # machine — each machine's local omniroute instance has its own token). Decrypted
  # at service start to a tmpfs env file; Yubikey touch prompted once per session.
  tokenGpg = "${config.xdg.configHome}/api_keys/omniroute_token.gpg";
  tokenEnvFile = "%t/omniroute-token.env";
in {
  options.opencodePlugins.omniroute.enable = lib.mkEnableOption "OmniRoute gateway + combo provisioning";

  config = lib.mkIf cfg.enable {
    # Install omniroute@<version> via npm into a versioned dir, prune old
    # versions, and update a `current` symlink — mirroring the opencode npm
    # plugin pin+prune pattern. Non-fatal: if npm install fails (no network)
    # the previous version stays via the `current` symlink.
    home.activation.installOmniroute = lib.hm.dag.entryAfter ["linkGeneration"] ''
      export PATH="${pkgs.nodejs}/bin:${pkgs.coreutils}/bin:$PATH"
      v="${version}"
      d="${dataDir}"
      vd="$d/omniroute@$v"

      if [ ! -x "$vd/node_modules/.bin/omniroute" ]; then
        echo "omniroute: installing $v ..."
        mkdir -p "$vd"
        if npm install --prefix "$vd" "omniroute@$v" 2>&1; then
          echo "omniroute: $v installed"
        else
          echo "omniroute: npm install failed, keeping previous version" >&2
        fi
      fi

      if [ -x "$vd/node_modules/.bin/omniroute" ]; then
        ln -sfn "$vd" "$d/current"

        # Clamp combo Retry-After hints so one member's far-future rate_limited_until cannot park clients ~1 day (idempotent; re-applies on every switch).
        ${pkgs.python3}/bin/python3 ${./patch-retry-hint.py} "$vd/node_modules/omniroute"
        # A combo skips a full litellm pool at once instead of queueing for it; pinned requests still wait (idempotent).
        ${pkgs.python3}/bin/python3 ${./patch-semaphore-failfast.py} "$vd/node_modules/omniroute"
        # Rules loaded at boot (the litellm 429 rule) must reach the chat route's own module copy (idempotent).
        ${pkgs.python3}/bin/python3 ${./patch-operator-rules-global.py} "$vd/node_modules/omniroute"
      fi

      for old in "$d"/omniroute@*; do
        [ -d "$old" ] || continue
        [ "$old" = "$vd" ] && continue
        rm -rf "$old"
      done
    '';

    systemd.user.services = {
      omniroute = {
        Unit = {
          Description = "OmniRoute AI gateway";
          After = ["network-online.target"];
          Wants = ["network-online.target"];
        };
        Install.WantedBy = ["default.target"];
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.nodejs}/bin/node ${omnirouteMjs}";
          Environment = [
            "PATH=${pkgs.nodejs}/bin"
            "TZ=Europe/Prague"
            "PORT=20128"
            # HOST is ignored by the gateway; only OMNIROUTE_SERVER_HOST binds the listener.
            "OMNIROUTE_SERVER_HOST=127.0.0.1"
            "REQUIRE_API_KEY=false"
            "DATA_DIR=${dataDir}/data"
            # Heavy-request cap: agent fan-out routinely exceeds 4; 16 x ~2 MB body still dwarfed by the 2240 MB V8 heap.
            "OMNIROUTE_CHAT_MAX_HEAVY_IN_FLIGHT=16"
            # Park bursts instead of 503-ing them; the 2 s default is shorter than one agent turn.
            "OMNIROUTE_CHAT_ADMISSION_QUEUE_MS=20000"
            # Waiters are charged their buffered body, so the 4 MiB default sheds after ~5 parked opencode requests.
            "OMNIROUTE_CHAT_ADMISSION_MAX_QUEUED_BYTES=67108864"
            # Only bodies past this count as heavy; 256 KiB default catches nearly every agent request.
            "OMNIROUTE_CHAT_LARGE_BODY_BYTES=1048576"
            # Bounds one upstream attempt, not the cooldown wait, which is awaited between fetches.
            "FETCH_TIMEOUT_MS=600000"
            # Total stream lifetime: the 21 min default kills a 128k-token Opus turn, which takes up to ~38 min at a measured 56 tok/s.
            "STREAM_ACTIVE_TIMEOUT_MS=3600000"
            # Cap the queue wait: 600 s let latched chains burn ~2 min per request; 4 s also bounds a full litellm pool before failover.
            "RATE_LIMIT_MAX_WAIT_MS=4000"
            # Backstop for limiter lease waits; 1 h let orphaned waits pile up after 600 s cap removal.
            "RATE_LIMIT_EXECUTION_MAX_WAIT_MS=120000"
            # Explicitly unbounded; any non-zero value turns on the queue_full fast-reject.
            "RATE_LIMIT_MAX_QUEUE_DEPTH=0"
            # Refresh the Claude/GH catalogs hourly; the 6 h default leaves a DNS blip pinned in the cache half the day.
            "MODEL_SYNC_INTERVAL_HOURS=1"
            # Starting the gateway before any link is up makes every lookup ENOTFOUND, which counts as a
            # provider failure: the 8/60s default latches the breaker long after connectivity returns.
            "OMNIROUTE_CIRCUIT_BREAKER_OAUTH_THRESHOLD=20"
            "OMNIROUTE_CIRCUIT_BREAKER_OAUTH_RESET_MS=20000"
          ];
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };

      # Idempotent combo provisioning — runs after omniroute boots, re-runs on
      # chains.json change (store path in ExecStart changes → unit restart).
      omniroute-provision = {
        Unit = {
          Description = "Provision OmniRoute combos from chains.json";
          After = ["omniroute.service"];
          PartOf = ["omniroute.service"];
        };
        Service = {
          Type = "oneshot";
          # Decrypt the admin API token to a tmpfs env file; `ask` because it is Yubikey-gated.
          ExecStartPre = "${pkgs.bash}/bin/bash -c '${gnupgTools.gpg-decrypt-hardened}/bin/gpg-decrypt-hardened --pinentry ask ${tokenGpg} > ${tokenEnvFile}'";
          EnvironmentFile = "-${tokenEnvFile}";
          ExecStart = "${provisionScript}/bin/omniroute-provision-combos ${./chains.json}";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -f ${tokenEnvFile}";
          RemainAfterExit = true;
          # Headroom over the wrapper's bounded retry (~47s worst case) vs systemd's 90s default.
          TimeoutStartSec = "120";
        };
        Install.WantedBy = ["omniroute.service"];
      };
    };
  };
}
