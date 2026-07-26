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
  inputs,
  ...
}: let
  cfg = config.opencodePlugins.graphify;

  # opencode skill layout (SKILL.md + references/) assembled from the pinned source; symlinked (skills tolerate store symlinks).
  skill = pkgs.runCommand "graphify-opencode-skill" {} ''
    mkdir -p "$out/references"
    cp ${inputs.graphify-src}/graphify/skill-opencode.md "$out/SKILL.md"
    cp ${inputs.graphify-src}/graphify/skills/opencode/references/*.md "$out/references/"
  '';
in {
  options.opencodePlugins.graphify = {
    enable = lib.mkEnableOption "graphify opencode integration (skill + tool.execute.before plugin + MCP server)";
    mcp.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Register the graphify MCP server (serves the per-project graphify-out/graph.json; loads lazily, safe with no graph present).";
    };
  };

  config = lib.mkIf cfg.enable {
    xdg.configFile."opencode/skills/graphify" = {
      source = skill;
      recursive = true;
    };

    # opencode's plugin sandbox rejects store symlinks, so install the plugin as REAL files from activation.
    home.activation.copyGraphifyPlugin = lib.hm.dag.entryAfter ["linkGeneration"] ''
      dir="$HOME/.config/opencode/plugins/graphify"
      mkdir -p "$dir"
      rm -f "$dir/plugin.js" "$dir/package.json"
      install -m 0644 ${./plugin.js}   "$dir/plugin.js"
      install -m 0644 ${./package.json} "$dir/package.json"
    '';
  };
}
