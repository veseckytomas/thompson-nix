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

  capsScript = pkgs.writeShellApplication {
    name = "omniroute-connection-caps";
    runtimeInputs = [pkgs.sqlite pkgs.coreutils];
    text = builtins.readFile ./connection-caps.sh;
  };
in {
  # Token-free like normalize-providers; gateway reads cap from DB per request, no restart needed.
  config = lib.mkIf cfg.enable {
    systemd.user.services.omniroute-connection-caps = {
      # Before=, not After=: gateway's PRAGMA journal_mode=WAL startup takes brief exclusive lock.
      Unit = {
        Description = "Provision OmniRoute litellm connection concurrency cap";
        Before = ["omniroute.service"];
        PartOf = ["omniroute.service"];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };

      Service = {
        Type = "oneshot";
        Environment = ["OMNIROUTE_DB=${dbPath}"];
        ExecStart = "${capsScript}/bin/omniroute-connection-caps";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install.WantedBy = ["omniroute.service"];
    };
  };
}
