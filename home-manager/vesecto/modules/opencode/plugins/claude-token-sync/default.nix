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
  cfg = config.opencodePlugins.claude-token-sync;
in {
  options.opencodePlugins.claude-token-sync = {
    enable = lib.mkEnableOption "claude-token-sync opencode plugin (mirror bridge token into ~/.claude for opencode-quota)";
  };

  config = lib.mkIf cfg.enable {
    # OpenCode's plugin sandbox rejects entries that resolve outside the plugin
    # directory via realpath, i.e. home-manager symlinks into /nix/store (see
    # caveman.nix). So the plugin's files must be REAL files in $HOME. We
    # provision them from this activation script rather than via xdg.configFile.
    #
    # `rm -f` clears prior state (real file from a previous switch, leftover
    # symlink, or missing); `install -m 0644` then writes fresh owner-writeable
    # copies so future activations replace them idempotently.
    home.activation.copyClaudeTokenSyncPlugin = lib.hm.dag.entryAfter ["linkGeneration"] ''
      dir="$HOME/.config/opencode/plugins/claude-token-sync"
      mkdir -p "$dir"
      rm -f "$dir/plugin.js" "$dir/package.json"
      install -m 0644 ${./plugin.js}   "$dir/plugin.js"
      install -m 0644 ${./package.json} "$dir/package.json"
    '';
  };
}
