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

  reasoningScript = pkgs.writeShellApplication {
    name = "omniroute-reasoning-rules";
    runtimeInputs = [pkgs.sqlite pkgs.coreutils];
    text = builtins.readFile ./reasoning-rules.sh;
  };
in {
  # Token-free; the gateway reads rules per request, so no restart is needed.
  config = lib.mkIf cfg.enable {
    systemd.user.services.omniroute-reasoning-rules = {
      # After=omniroute-provision, not Before=omniroute: provisioning re-creates combos, and ON DELETE CASCADE would wipe rules bound to the old ids.
      Unit = {
        Description = "Provision OmniRoute combo reasoning-effort rules";
        After = ["omniroute-provision.service"];
        PartOf = ["omniroute.service"];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };

      Service = {
        Type = "oneshot";
        Environment = ["OMNIROUTE_DB=${dbPath}"];
        ExecStart = "${reasoningScript}/bin/omniroute-reasoning-rules";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install.WantedBy = ["omniroute-provision.service"];
    };
  };
}
