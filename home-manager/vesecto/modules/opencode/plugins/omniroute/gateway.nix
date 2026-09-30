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
          # Decrypt the admin API token to a tmpfs env file (gpg-agent + Yubikey).
          ExecStartPre = "${pkgs.bash}/bin/bash -c '${pkgs.gnupg}/bin/gpg --decrypt -q ${tokenGpg} > ${tokenEnvFile}'";
          EnvironmentFile = "-${tokenEnvFile}";
          ExecStart = "${provisionScript}/bin/omniroute-provision-combos ${./chains.json}";
          ExecStopPost = "${pkgs.coreutils}/bin/rm -f ${tokenEnvFile}";
          RemainAfterExit = true;
        };
        Install.WantedBy = ["omniroute.service"];
      };
    };
  };
}
