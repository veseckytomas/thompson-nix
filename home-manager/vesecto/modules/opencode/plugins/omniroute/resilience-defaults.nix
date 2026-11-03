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

  resilienceScript = pkgs.writeShellApplication {
    name = "omniroute-resilience-defaults";
    runtimeInputs = [pkgs.sqlite pkgs.jq pkgs.coreutils];
    text = builtins.readFile ./resilience-defaults.sh;
  };
in {
  # Token-free like normalize-providers; the gateway reads this row as an override, so no restart is needed.
  config = lib.mkIf cfg.enable {
    systemd.user.services.omniroute-resilience-defaults = {
      # Before=, not After=: the gateway's PRAGMA journal_mode=WAL on startup takes a brief exclusive lock.
      Unit = {
        Description = "Provision OmniRoute resilience cooldown defaults";
        Before = ["omniroute.service"];
        PartOf = ["omniroute.service"];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        Type = "oneshot";
        Environment = ["OMNIROUTE_DB=${dbPath}"];
        ExecStart = "${resilienceScript}/bin/omniroute-resilience-defaults";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["omniroute.service"];
    };
  };
}
