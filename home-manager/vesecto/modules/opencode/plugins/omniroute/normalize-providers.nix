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
  dbPath = "${config.xdg.dataHome}/omniroute/data/storage.sqlite";

  normalizeScript = pkgs.writeShellApplication {
    name = "omniroute-normalize-providers";
    runtimeInputs = [pkgs.sqlite pkgs.coreutils];
    text = builtins.readFile ./normalize-providers.sh;
  };
in {
  # Token-free DB fix, kept out of omniroute-provision so it never waits on the Yubikey-gated admin token.
  config = lib.mkIf cfg.enable {
    systemd.user.services.omniroute-normalize-providers = {
      # Before=, not After=: the gateway's PRAGMA journal_mode=WAL on startup takes a brief exclusive lock.
      Unit = {
        Description = "Normalize OmniRoute Antigravity provider key (agy → antigravity)";
        Before = ["omniroute.service"];
        PartOf = ["omniroute.service"];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        Type = "oneshot";
        Environment = ["OMNIROUTE_DB=${dbPath}"];
        ExecStart = "${normalizeScript}/bin/omniroute-normalize-providers";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["omniroute.service"];
    };
  };
}
