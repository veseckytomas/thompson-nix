#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / /_/ (__  ) /_/ / / / /
# / / / / / / /_/ / /_/ / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
#
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.opencodePlugins.omniroute;

  dbPath = "${config.xdg.dataHome}/omniroute/data/storage.sqlite";

  vocabScript = pkgs.writeShellApplication {
    name = "omniroute-kimi-effort-vocab";
    runtimeInputs = [pkgs.sqlite pkgs.coreutils];
    text = builtins.readFile ./kimi-effort-vocab.sh;
  };
in {
  # Token-free like connection-caps; Before= (gateway WAL startup lock); no restart needed (fresh bulk snapshot).
  config = lib.mkIf cfg.enable {
    systemd.user.services.omniroute-kimi-effort-vocab = {
      Unit = {
        Description = "Seed OmniRoute litellm/kimi-k3 thinking_effort vocabulary override";
        Before = ["omniroute.service"];
        PartOf = ["omniroute.service"];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 3;
      };

      Service = {
        Type = "oneshot";
        Environment = ["OMNIROUTE_DB=${dbPath}"];
        ExecStart = "${vocabScript}/bin/omniroute-kimi-effort-vocab";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 2;
      };

      Install.WantedBy = ["omniroute.service"];
    };
  };
}
