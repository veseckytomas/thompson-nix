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
  opencodeConfigDir = "${config.home.homeDirectory}/.config/opencode";
  opencodeCaveman = pkgs.runCommand "opencode-caveman" {} ''
    mkdir -p \
      "$out/opencode/plugins/caveman" \
      "$out/opencode/commands" \
      "$out/opencode/agents" \
      "$out/opencode/skills"

    cp ${inputs.caveman}/src/plugins/opencode/plugin.js "$out/opencode/plugins/caveman/"
    cp ${inputs.caveman}/src/plugins/opencode/package.json "$out/opencode/plugins/caveman/"
    cp ${inputs.caveman}/src/hooks/caveman-config.js "$out/opencode/plugins/caveman/caveman-config.cjs"

    cp -R ${inputs.caveman}/src/plugins/opencode/commands/. "$out/opencode/commands/"
    cp -R ${inputs.caveman}/agents/. "$out/opencode/agents/"
    cp -R ${inputs.caveman}/skills/. "$out/opencode/skills/"
    cp ${inputs.caveman}/src/rules/caveman-activate.md "$out/opencode/AGENTS.md"

    substituteInPlace "$out/opencode/agents/cavecrew-builder.md" \
      --replace "tools: [Read, Edit, Write, Grep, Glob]" "tools: { read: true, edit: true, write: true, grep: true, glob: true }"
    substituteInPlace "$out/opencode/agents/cavecrew-investigator.md" \
      --replace "tools: [Read, Grep, Glob, Bash]" "tools: { read: true, grep: true, glob: true, bash: true }"
    substituteInPlace "$out/opencode/agents/cavecrew-reviewer.md" \
      --replace "tools: [Read, Grep, Bash]" "tools: { read: true, grep: true, bash: true }"

    sed -i '/^model: haiku$/d' "$out/opencode/agents/cavecrew-investigator.md"
    sed -i '/^model: haiku$/d' "$out/opencode/agents/cavecrew-reviewer.md"
  '';
in {
  options.opencodePlugins.caveman = {
    enable = lib.mkEnableOption "Caveman plugin";
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
    };
  };

  config = lib.mkIf config.opencodePlugins.caveman.enable {
    opencodePlugins = {
      caveman.package = opencodeCaveman;
      agentSources = ["${opencodeCaveman}/opencode/agents"];
      pluginEntries = ["${opencodeConfigDir}/plugins/caveman/plugin.js"];
    };

    xdg.configFile = {
      "opencode/plugins/caveman".source = "${opencodeCaveman}/opencode/plugins/caveman";
      "opencode/commands".source = "${opencodeCaveman}/opencode/commands";
      "opencode/skills".source = "${opencodeCaveman}/opencode/skills";
      "opencode/AGENTS.md".source = "${opencodeCaveman}/opencode/AGENTS.md";
    };
  };
}
