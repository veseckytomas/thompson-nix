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
  ...
}: let
  cfg = config.opencodePlugins.system-message-hoist;
in {
  options.opencodePlugins.system-message-hoist = {
    enable = lib.mkEnableOption "system-message-hoist opencode plugin (merge system messages into one leading message so qwen3.5's vLLM template stops 400ing subagent calls)";
  };

  config = lib.mkIf cfg.enable {
    # opencode's plugin sandbox realpaths entries, so files must be REAL in $HOME (see cache-control-cap) — provision via activation, not symlinks.
    home.activation.copySystemMessageHoistPlugin = lib.hm.dag.entryAfter ["linkGeneration"] ''
      dir="$HOME/.config/opencode/plugins/system-message-hoist"
      mkdir -p "$dir"
      rm -f "$dir/plugin.js" "$dir/package.json"
      install -m 0644 ${./plugin.js}   "$dir/plugin.js"
      install -m 0644 ${./package.json} "$dir/package.json"
    '';
  };
}
