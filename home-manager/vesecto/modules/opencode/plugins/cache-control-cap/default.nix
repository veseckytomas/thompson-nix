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
  cfg = config.opencodePlugins.cache-control-cap;
in {
  options.opencodePlugins.cache-control-cap = {
    enable = lib.mkEnableOption "cache-control-cap opencode plugin (cap outbound Anthropic requests at 4 cache_control breakpoints)";
  };

  config = lib.mkIf cfg.enable {
    # OpenCode's plugin sandbox rejects entries that resolve outside the plugin
    # directory via realpath, so the files must be REAL in $HOME (see
    # claude-token-sync). Provision from activation, not xdg.configFile symlinks.
    home.activation.copyCacheControlCapPlugin = lib.hm.dag.entryAfter ["linkGeneration"] ''
      dir="$HOME/.config/opencode/plugins/cache-control-cap"
      mkdir -p "$dir"
      rm -f "$dir/plugin.js" "$dir/package.json"
      install -m 0644 ${./plugin.js}   "$dir/plugin.js"
      install -m 0644 ${./package.json} "$dir/package.json"
    '';
  };
}
