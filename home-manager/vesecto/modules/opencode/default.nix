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
  ...
}: {
  options.opencodePlugins = {
    agentSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Agent directory sources from enabled plugins";
    };
    pluginEntries = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Plugin entries for opencode settings from enabled plugins";
    };
    tuiPluginEntries = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "TUI plugin entries from enabled plugins";
    };
    commandSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Command directory sources from enabled plugins";
    };
    skillSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Skill directory sources from enabled plugins";
    };
  };

  imports = [
    ./plugins/gsd.nix
    ./plugins/caveman.nix
    ./plugins/wakatime.nix
    ./plugins/oh-my-openagent.nix
    ./plugins/superpowers.nix
  ];

  config = let
    opencodeAgents = pkgs.runCommand "opencode-agents" {} ''
      mkdir -p "$out"
      ${lib.concatMapStrings (src: ''
          cp -R ${src}/. "$out"/
        '')
        config.opencodePlugins.agentSources}
    '';
    opencodeCommands = pkgs.runCommand "opencode-commands" {} ''
      mkdir -p "$out"
      ${lib.concatMapStrings (src: ''
          cp -R ${src}/. "$out"/
        '')
        config.opencodePlugins.commandSources}
    '';
    opencodeSkills = pkgs.runCommand "opencode-skills" {} ''
      mkdir -p "$out"
      ${lib.concatMapStrings (src: ''
          cp -R ${src}/. "$out"/
        '')
        config.opencodePlugins.skillSources}
    '';
  in {
    opencodePlugins = {
      gsd.enable = true;
      caveman.enable = false;
      wakatime.enable = true;
      oh-my-openagent.enable = true;
      superpowers.enable = true;
    };

    xdg.configFile = {
      "opencode/agents".source = opencodeAgents;
      "opencode/command".source = opencodeCommands;
      "opencode/skills".source = opencodeSkills;
    };

    programs.opencode = {
      enable = true;
      enableMcpIntegration = true;
      settings = {
        autoupdate = false;
        lsp = true;
        model = "litellm/kimi-k2.6";
        plugin = config.opencodePlugins.pluginEntries;
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
        plugin = config.opencodePlugins.tuiPluginEntries;
        theme = "catppuccin";
      };
    };
  };
}
