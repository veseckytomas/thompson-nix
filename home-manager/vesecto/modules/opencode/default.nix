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
{pkgs, ...}: {
  opencodePlugins = {
    omo.enable = false;
    gsd-sdk.enable = true;
    gsd.enable = true;
    caveman.enable = true;
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      autoupdate = false;
      lsp = true;
      model = "litellm/kimi-k2.6";
      plugin = [
        "./plugins/caveman/plugin.js"
        "oh-my-openagent"
        "./plugins/superpowers/plugin.js"
        "opencode-wakatime"
        "opencode-codex-quota"
        "opencode-gemini-auth@latest"
        "opencode-claude-bridge"
      ];
      provider = {
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
      permission = {
        external_directory = {
          "/tmp/**" = "allow";
        };
      };
      compaction = {
        auto = true;
        prune = false;
        tail_turns = 2;
        preserve_recent_tokens = 0;
        reserved = 0;
      };
    };
    tui = {
      theme = "catppuccin";
      plugin = ["oh-my-openagent/tui"];
    };
  };
  imports = [
    ./plugins
  ];

  xdg.configFile."opencode/skills" = {
    source = ./skills;
    recursive = true;
  };

  home.packages = [
    pkgs.wakatime-cli
  ];
}
