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
  opencodeOhMyOpenagentDeps = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent-deps";
    version = "4.5.1";
    src = inputs.oh-my-openagent;

    nativeBuildInputs = [pkgs.bun pkgs.cacert];

    dontConfigure = true;
    dontFixup = true;

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-i2AtcrGw9OJ/40GbXhHBopjLWUOtwfLnQvGjBH9HumQ=";

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

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

  opencodeOhMyOpenagent = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent";
    version = "4.5.1";
    src = inputs.oh-my-openagent;

    nativeBuildInputs = [pkgs.bun pkgs.nodejs_22];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      cp -R ${opencodeOhMyOpenagentDeps}/node_modules ./node_modules
      chmod -R u+w node_modules
      patchShebangs node_modules

      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export OMO_SEND_ANONYMOUS_TELEMETRY=0
      export OMO_DISABLE_POSTHOG=1

      bun run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall


      mkdir -p "$out" "$out/opencode"
      cp -R \
        package.json \
        bin \
        dist \
        node_modules \
        packages \
        "$out"/

      cp -R .opencode/command "$out/opencode/command"
      cp -R .opencode/skills "$out/opencode/skills"
      cp .opencode/AGENTS.md "$out/opencode/AGENTS.md"

      runHook postInstall
    '';
  };

  ohMyOpenagentConfig =
    pkgs.runCommand "oh-my-openagent-config" {
      nativeBuildInputs = [pkgs.bun];
    } ''
      mkdir -p "$TMPDIR/source" "$out"
      cp -R ${inputs.oh-my-openagent}/. "$TMPDIR/source"/
      chmod -R u+rwX "$TMPDIR/source"
      cp -R ${opencodeOhMyOpenagentDeps}/node_modules "$TMPDIR/source"/
      chmod -R u+w "$TMPDIR/source/node_modules"

      cat > "$TMPDIR/generate-oh-my-openagent-config.ts" <<'EOF'
      import { generateModelConfig } from "./source/src/cli/model-fallback"

      const OPENAI_MODELS = new Set(["gpt-5.5"])
      const LITELLM_MODELS = new Set([
        "deepseek-r1",
        "deepseek-v4-pro-thinking",
        "deepseek-v4-pro",
        "gpt-oss-120b",
        "qwen3-coder",
        "glm-5.1",
        "kimi-k2.6",
      ])

      function useConfiguredProviderModel(model: string): string {
        const modelName = model.replace(/^[^/]+\//, "")

        if (OPENAI_MODELS.has(modelName)) {
          return `openai/''${modelName}`
        }

        if (LITELLM_MODELS.has(modelName)) {
          return `litellm/''${modelName}`
        }

        return "litellm/kimi-k2.6"
      }

      function useConfiguredProviderModels(value: unknown): unknown {
        if (Array.isArray(value)) {
          return value.map(useConfiguredProviderModels)
        }

        if (value && typeof value === "object") {
          return Object.fromEntries(
            Object.entries(value).map(([key, entry]) => [
              key,
              key === "model" && typeof entry === "string"
                ? useConfiguredProviderModel(entry)
                : useConfiguredProviderModels(entry),
            ]),
          )
        }

        return value
      }

      const config = generateModelConfig({
        hasClaude: true,
        isMax20: false,
        hasOpenAI: true,
        hasGemini: true,
        hasCopilot: true,
        hasOpencodeZen: true,
        hasZaiCodingPlan: false,
        hasKimiForCoding: false,
        hasOpencodeGo: false,
        hasVercelAiGateway: false,
      })

      console.log(JSON.stringify({
        ...(useConfiguredProviderModels(config) as typeof config),
        team_mode: {
          enabled: true,
          max_parallel_members: 4,
          tmux_visualization: true,
        },
      }, null, 2))
      EOF

      cd "$TMPDIR"
      bun run "$TMPDIR/generate-oh-my-openagent-config.ts" > "$out/oh-my-openagent.jsonc"
    '';
in {
  options.opencodePlugins.oh-my-openagent = {
    enable = lib.mkEnableOption "Oh My OpenAgent plugin";
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
    };
  };

  config = lib.mkIf config.opencodePlugins.oh-my-openagent.enable {
    opencodePlugins = {
      oh-my-openagent.package = opencodeOhMyOpenagent;
      commandSources = ["${opencodeOhMyOpenagent}/opencode/command"];
      pluginEntries = ["file://${opencodeOhMyOpenagent}"];
      skillSources = ["${opencodeOhMyOpenagent}/opencode/skills"];
      tuiPluginEntries = ["file://${opencodeOhMyOpenagent}"];
    };

    xdg.configFile = {
      "opencode/oh-my-openagent".source = opencodeOhMyOpenagent;
      "opencode/oh-my-openagent.jsonc".source = "${ohMyOpenagentConfig}/oh-my-openagent.jsonc";
    };

    home.sessionVariables = {
      OMO_SEND_ANONYMOUS_TELEMETRY = "0";
      OMO_DISABLE_POSTHOG = "1";
    };
  };
}
