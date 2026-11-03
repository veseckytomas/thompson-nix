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

  compressionScript = pkgs.writeShellApplication {
    name = "omniroute-compression-defaults";
    runtimeInputs = [pkgs.sqlite pkgs.jq pkgs.coreutils];
    text = builtins.readFile ./compression-defaults.sh;
  };
in {
  config = lib.mkIf cfg.enable {
    systemd.user.services.omniroute-compression-defaults = {
      # Before=, not After=: the gateway's PRAGMA journal_mode=WAL on startup takes a brief exclusive lock.
      Unit = {
        Description = "Provision OmniRoute compression engine defaults";
        Before = ["omniroute.service"];
        PartOf = ["omniroute.service"];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };
      Service = {
        Type = "oneshot";
        Environment = ["OMNIROUTE_DB=${dbPath}"];
        ExecStart = "${compressionScript}/bin/omniroute-compression-defaults";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 2;
      };
      Install.WantedBy = ["omniroute.service"];
    };
  };
}
