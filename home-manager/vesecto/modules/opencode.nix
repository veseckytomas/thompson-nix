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
  opencodeGsd =
    pkgs.runCommand "opencode-gsd" {
      nativeBuildInputs = [pkgs.nodejs_22];
    } ''
      mkdir -p "$out" "$TMPDIR/home"

      export HOME="$TMPDIR/home"
      export XDG_CONFIG_HOME="$TMPDIR/home/.config"
      export GSD_SKIP_STALE_SDK_CHECK=1

      ${pkgs.nodejs_22}/bin/node \
        ${inputs.get-shit-done-redux}/bin/install.js \
        --opencode \
        --global \
        --no-sdk \
        --config-dir "$out"

      rm -f "$out/opencode.json"
      rm -f "$out/gsd-file-manifest.json"

      while IFS= read -r -d "" file; do
        substituteInPlace "$file" --replace "$out" "${opencodeConfigDir}"
      done < <(find "$out" -type f -print0)
    '';
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
  opencodeAgents = pkgs.runCommand "opencode-agents" {} ''
    mkdir -p "$out"
    cp -R ${opencodeGsd}/agents/. "$out"/
    cp -R ${opencodeCaveman}/opencode/agents/. "$out"/
  '';
  opencodeWakatimeDeps = pkgs.stdenv.mkDerivation {
    pname = "opencode-wakatime-deps";
    version = "1.3.8";
    src = inputs.opencode-wakatime;

    nativeBuildInputs = [pkgs.nodejs_22 pkgs.cacert];

    dontConfigure = true;
    dontFixup = true;

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-LH+rlOOF2QjMczVxbj5Lc3LcM4wc4w8dDHc+ExThpRs=";

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      npm install --frozen-lockfile --ignore-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R node_modules "$out"/

      runHook postInstall
    '';
  };
  opencodeWakatime = pkgs.stdenv.mkDerivation {
    pname = "opencode-wakatime";
    version = "1.3.8";
    src = inputs.opencode-wakatime;

    nativeBuildInputs = [pkgs.nodejs_22];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      cp -R ${opencodeWakatimeDeps}/node_modules ./node_modules
      chmod -R u+w node_modules
      patchShebangs node_modules

      export HOME="$TMPDIR/home"

      npm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R \
        package.json \
        dist \
        "$out"/

      runHook postInstall
    '';
  };
  opencodeOhMyOpenAgentDeps = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent-deps";
    version = "4.4.0-dev";
    src = inputs.oh-my-openagent;

    nativeBuildInputs = [pkgs.bun];

    dontConfigure = true;
    dontFixup = true;

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-MZzLQhas31hM2CvHJZXgQZVJQulJUAd5SDiMnv9ZUe4=";

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"

      bun install --frozen-lockfile --ignore-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R node_modules "$out"/

      runHook postInstall
    '';
  };
  opencodeOhMyOpenAgent = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent-opencode-plugin";
    version = "4.4.0-dev";
    src = inputs.oh-my-openagent;

    nativeBuildInputs = [
      pkgs.bun
      pkgs.nodejs_22
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      cp -R ${opencodeOhMyOpenAgentDeps}/node_modules ./node_modules
      chmod -R u+w node_modules
      patchShebangs node_modules

      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"

      bun run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R \
        package.json \
        bin \
        dist \
        node_modules \
        .opencode \
        packages \
        assets \
        "$out"/

      runHook postInstall
    '';
  };
in {
  xdg.configFile."opencode/agents".source = opencodeAgents;
  xdg.configFile."opencode/command".source = "${opencodeGsd}/command";
  xdg.configFile."opencode/get-shit-done".source = "${opencodeGsd}/get-shit-done";
  xdg.configFile."opencode/hooks".source = "${opencodeGsd}/hooks";
  xdg.configFile."opencode/package.json".source = "${opencodeGsd}/package.json";
  xdg.configFile."opencode/plugins/caveman".source = "${opencodeCaveman}/opencode/plugins/caveman";
  xdg.configFile."opencode/commands".source = "${opencodeCaveman}/opencode/commands";
  xdg.configFile."opencode/skills".source = "${opencodeCaveman}/opencode/skills";
  xdg.configFile."opencode/AGENTS.md".source = "${opencodeCaveman}/opencode/AGENTS.md";
  xdg.configFile."opencode/superpowers".source = inputs.superpowers;
  xdg.configFile."opencode/wakatime".source = opencodeWakatime;
  xdg.configFile."opencode/oh-my-openagent".source = opencodeOhMyOpenAgent;

  home.sessionVariables = {
    OMO_DISABLE_POSTHOG = "1";
    OMO_SEND_ANONYMOUS_TELEMETRY = "0";
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      autoupdate = false;
      lsp = true;
      model = "openai/gpt-5.5";
      permission = {
        read."${opencodeConfigDir}/get-shit-done/*" = "allow";
        external_directory."${opencodeConfigDir}/get-shit-done/*" = "allow";
      };
      plugin = [
        "file:${opencodeConfigDir}/wakatime"
        "${opencodeConfigDir}/plugins/caveman/plugin.js"
        "${opencodeConfigDir}/superpowers"
        "file:${opencodeConfigDir}/oh-my-openagent"
      ];
      provider = {
        openai = {
          whitelist = [
            "gpt-5.5"
          ];
        };
        litellm = {
          npm = "@ai-sdk/openai-compatible";
          name = "LiteLLM";
          options = {
            baseURL = "https://llm.ai.e-infra.cz/v1";
          };
          models = {
            deepseek-r1 = {
              name = "deepseek-r1";
            };
            deepseek-v4-pro-thinking = {
              name = "deepseek-v4-pro-thinking";
            };
            deepseek-v4-pro = {
              name = "deepseek-v4-pro";
            };
            gpt-oss-120b = {
              name = "gpt-oss-120b";
            };
            qwen3-coder = {
              name = "qwen3-coder";
            };
            "glm-5.1" = {
              name = "glm-5.1";
            };
            "kimi-k2.6" = {
              name = "kimi-k2.6";
            };
          };
        };
      };
    };
    tui = {
      plugin = [
        "file:${opencodeConfigDir}/oh-my-openagent"
      ];
      theme = "catppuccin";
    };
  };
}
