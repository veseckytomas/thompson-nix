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
  opencodeOhMyOpenAgentDeps =
    pkgs.stdenv.mkDerivation {
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
  opencodeOhMyOpenAgent =
    pkgs.stdenv.mkDerivation {
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
  xdg.configFile."opencode/agents".source = "${opencodeGsd}/agents";
  xdg.configFile."opencode/command".source = "${opencodeGsd}/command";
  xdg.configFile."opencode/get-shit-done".source = "${opencodeGsd}/get-shit-done";
  xdg.configFile."opencode/hooks".source = "${opencodeGsd}/hooks";
  xdg.configFile."opencode/package.json".source = "${opencodeGsd}/package.json";
  xdg.configFile."opencode/superpowers".source = inputs.superpowers;
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
      permission = {
        read."${opencodeConfigDir}/get-shit-done/*" = "allow";
        external_directory."${opencodeConfigDir}/get-shit-done/*" = "allow";
      };
      plugin = [
        "opencode-wakatime"
        "${opencodeConfigDir}/superpowers"
        "${opencodeConfigDir}/oh-my-openagent"
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
            "glm-4.7" = {
              name = "glm-4.7";
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
      theme = "catppuccin";
    };
  };
}
