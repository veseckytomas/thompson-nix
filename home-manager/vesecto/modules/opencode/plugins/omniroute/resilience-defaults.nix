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
  dbPath = "${config.xdg.dataHome}/omniroute/data/storage.sqlite";

  resilienceScript = pkgs.writeShellApplication {
    name = "omniroute-resilience-defaults";
    runtimeInputs = [pkgs.sqlite pkgs.jq pkgs.coreutils];
    text = builtins.readFile ./resilience-defaults.sh;
  };
in {
  # Token-free like normalize-providers; the 5s settings TTL means no gateway restart.
  config = lib.mkIf cfg.enable {
    systemd.user.services.omniroute-resilience-defaults = {
      Unit = {
        Description = "Provision OmniRoute resilience cooldown defaults";
        After = ["omniroute.service"];
        PartOf = ["omniroute.service"];
      };
      Service = {
        Type = "oneshot";
        Environment = ["OMNIROUTE_DB=${dbPath}"];
        ExecStart = "${resilienceScript}/bin/omniroute-resilience-defaults";
        RemainAfterExit = true;
      };
      Install.WantedBy = ["omniroute.service"];
    };
  };
}
