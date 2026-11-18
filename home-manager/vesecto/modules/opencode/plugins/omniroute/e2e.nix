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
  gatewayService,
}: let
  # The deployed unit's own env, minus what the throwaway gateway must own.
  owned = ["PATH" "DATA_DIR"];
  gatewayEnv = builtins.filter (e: !(builtins.elem (builtins.head (builtins.split "=" e)) owned)) gatewayService.Environment;
in
  pkgs.writeShellApplication {
    name = "omniroute-e2e";
    runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.gawk pkgs.gnugrep pkgs.iproute2 pkgs.jq pkgs.python3 pkgs.sqlite pkgs.util-linux];
    runtimeEnv = {
      E2E_MOCK = ./e2e-mock-upstream.py;
      E2E_PATCHER = ./patch-semaphore-failfast.py;
      E2E_RULES_PATCHER = ./patch-operator-rules-global.py;
      E2E_CAPS = ./connection-caps.sh;
      E2E_RESILIENCE = ./resilience-defaults.sh;
      E2E_GATEWAY_ENV = builtins.concatStringsSep "\n" (["PATH=${pkgs.nodejs}/bin"] ++ gatewayEnv);
      # Home Manager normalizes ExecStart to a list; only its node binary is reused, the entry point is the overlaid one.
      E2E_NODE = builtins.head (builtins.split " " (builtins.head (pkgs.lib.toList gatewayService.ExecStart)));
    };
    text = builtins.readFile ./e2e.sh;
  }
