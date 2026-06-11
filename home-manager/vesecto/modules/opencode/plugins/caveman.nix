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
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.opencodePlugins.caveman;

  # The caveman JS plugin (hooks for TUI caveman-mode).  This is loaded as a
  # local plugin (see settings.plugin).  It only contains the entry-point and
  # the config helper — agents/commands/skills live in the global opencode
  # directories where opencode actually scans for them.
  cavemanPlugin = pkgs.runCommand "caveman-opencode-plugin" {} ''
    mkdir -p $out
    cp ${inputs.caveman}/src/plugins/opencode/plugin.js $out/
    cp ${inputs.caveman}/src/plugins/opencode/package.json $out/
    cp ${inputs.caveman}/src/hooks/caveman-config.js $out/caveman-config.cjs
  '';

  # Caveman agent files ship with two opencode-incompatible YAML front-matter
  # features:
  #   1. `tools: [Read, Edit, Write, Grep, Glob]` — a JSON-style array that
  #      opencode's YAML parser (js-yaml in JSON_SCHEMA mode) crashes on.
  #   2. `description: >` folded block scalars which opencode silently drops.
  # GSD agents use single-line descriptions and include `mode: subagent`.
  # We strip `tools:`, flatten `description: >` to a single line, and inject
  # `mode: subagent`.
  cavemanAgents = pkgs.runCommand "caveman-opencode-agents" {} ''
    mkdir -p $out
    for src in ${inputs.caveman}/agents/cavecrew-builder.md \
               ${inputs.caveman}/agents/cavecrew-investigator.md \
               ${inputs.caveman}/agents/cavecrew-reviewer.md; do
      dst="$out/$(basename "$src")"
      awk 'BEGIN { in_desc=0; desc=""; seen_name=0 }
           /^tools:/ { next }
           in_desc && /^[^ \t]/ { print "description: " desc; in_desc=0 }
           in_desc { sub(/^[ \t]+/,""); if (length>0) { if (desc=="") desc=$0; else desc=desc" "$0 }; next }
           /^description: >/ { in_desc=1; desc=""; next }
           /^---$/ && seen_name { print "mode: subagent" }
           { print; if (/^name:/) seen_name=1 }' "$src" > "$dst"
    done
  '';
in {
  options.opencodePlugins.caveman = {
    enable = lib.mkEnableOption "Caveman opencode plugin";
  };

  config = lib.mkIf cfg.enable {
    # Plugin entry point (TUI hooks, slash-command handling) loaded as a local
    # plugin by opencode.
    xdg.configFile."opencode/plugins/caveman" = {
      source = cavemanPlugin;
      recursive = true;
    };

    # OpenCode's plugin sandbox rejects server entries that resolve outside
    # the plugin directory via realpath. Copy the critical entry-point files
    # as real files after linkGeneration.
    #
    # `rm -f` handles all prior states: home-manager symlink (first switch),
    # read-only 0444 regular file (copied from Nix store on a previous switch),
    # or missing. `install -m 0644` then writes a fresh owner-writeable copy
    # so future activations can replace it idempotently.
    home.activation.copyCavemanPluginEntry = lib.hm.dag.entryAfter ["linkGeneration"] ''
      cavemanDir="$HOME/.config/opencode/plugins/caveman"
      mkdir -p "$cavemanDir"
      rm -f "$cavemanDir/plugin.js" \
            "$cavemanDir/package.json" \
            "$cavemanDir/caveman-config.cjs"
      install -m 0644 "${cavemanPlugin}/plugin.js"          "$cavemanDir/plugin.js"
      install -m 0644 "${cavemanPlugin}/package.json"       "$cavemanDir/package.json"
      install -m 0644 "${cavemanPlugin}/caveman-config.cjs" "$cavemanDir/caveman-config.cjs"
    '';


    # Agents discovered by opencode's global agent scanner from
    # ~/.config/opencode/agents/ (same directory GSD uses).
    xdg.configFile."opencode/agents/cavecrew-builder.md".source = "${cavemanAgents}/cavecrew-builder.md";
    xdg.configFile."opencode/agents/cavecrew-investigator.md".source = "${cavemanAgents}/cavecrew-investigator.md";
    xdg.configFile."opencode/agents/cavecrew-reviewer.md".source = "${cavemanAgents}/cavecrew-reviewer.md";

    # Commands discovered by opencode's global command scanner.
    xdg.configFile."opencode/commands/caveman.md".source =
      inputs.caveman + "/src/plugins/opencode/commands/caveman.md";
    xdg.configFile."opencode/commands/caveman-commit.md".source =
      inputs.caveman + "/src/plugins/opencode/commands/caveman-commit.md";
    xdg.configFile."opencode/commands/caveman-help.md".source =
      inputs.caveman + "/src/plugins/opencode/commands/caveman-help.md";
    xdg.configFile."opencode/commands/caveman-review.md".source =
      inputs.caveman + "/src/plugins/opencode/commands/caveman-review.md";
    xdg.configFile."opencode/commands/caveman-stats.md".source =
      inputs.caveman + "/src/plugins/opencode/commands/caveman-stats.md";

    # Skills discovered by opencode's global skill scanner.
    xdg.configFile."opencode/skills/cavecrew" = {
      source = inputs.caveman + "/skills/cavecrew";
      recursive = true;
    };
    xdg.configFile."opencode/skills/caveman" = {
      source = inputs.caveman + "/skills/caveman";
      recursive = true;
    };
    xdg.configFile."opencode/skills/caveman-commit" = {
      source = inputs.caveman + "/skills/caveman-commit";
      recursive = true;
    };
    xdg.configFile."opencode/skills/caveman-compress" = {
      source = inputs.caveman + "/skills/caveman-compress";
      recursive = true;
    };
    xdg.configFile."opencode/skills/caveman-help" = {
      source = inputs.caveman + "/skills/caveman-help";
      recursive = true;
    };
    xdg.configFile."opencode/skills/caveman-review" = {
      source = inputs.caveman + "/skills/caveman-review";
      recursive = true;
    };
    xdg.configFile."opencode/skills/caveman-stats" = {
      source = inputs.caveman + "/skills/caveman-stats";
      recursive = true;
    };
  };
}
