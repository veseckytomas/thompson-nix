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
  ...
}: let
  cfg = config.opencodePlugins.session-list-all;
in {
  options.opencodePlugins.session-list-all = {
    enable = lib.mkEnableOption "session-list-all opencode plugin (list sessions across all directories)";
  };

  config = lib.mkIf cfg.enable {
    # opencode's plugin sandbox rejects store symlinks, so install the plugin as REAL files from activation.
    home.activation.copySessionListAllPlugin = lib.hm.dag.entryAfter ["linkGeneration"] ''
      dir="''${XDG_CONFIG_HOME:-$HOME/.config}/opencode/plugins/session-list-all"
      run mkdir -p "$dir"
      run rm -f "$dir/plugin.js" "$dir/index.js" "$dir/package.json"
      run install -m 0644 ${./index.js} "$dir/index.js"
      run install -m 0644 ${./package.json} "$dir/package.json"
    '';
  };
}
