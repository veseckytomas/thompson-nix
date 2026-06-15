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
  pkgs,
  lib,
  config,
  ...
}: {
  opencodePlugins = {
    omo.enable = true;
    gsd-sdk.enable = true;
    gsd.enable = true;
    caveman.enable = true;
    claude-token-sync.enable = true;
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      autoupdate = false;
      lsp = true;
      model = "litellm/kimi-k2.6";
      plugin =
        [
          "./plugins/caveman/plugin.js"
        ]
        ++ lib.optional config.opencodePlugins.omo.enable "./node_modules/oh-my-openagent"
        ++ [
          "./plugins/superpowers/plugin.js"
          "opencode-wakatime"
          "opencode-claude-bridge"
          "opencode-gemini-auth"
          "./plugins/claude-token-sync/plugin.js"
          "@slkiser/opencode-quota"
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
      mcp = {
        markitdown = {
          type = "local";
          command = ["${pkgs.markitdown-mcp}/bin/markitdown-mcp"];
          enabled = true;
        };
      };
    };
    tui = {
      theme = "catppuccin";
      plugin = ["@slkiser/opencode-quota"];
    };
  };
  imports = [
    ./plugins
  ];

  xdg.configFile = {
    "opencode/skills" = {
      source = ./skills;
      recursive = true;
    };
    "opencode/opencode-quota/quota-toast.json" = {
      source = ./plugins/opencode-quota.json;
    };
  };

  home.packages = [
    pkgs.wakatime-cli
    pkgs.python3Packages.markitdown
  ];
}
