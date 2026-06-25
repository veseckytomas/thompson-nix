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
}: let
  # CodeGraph, rebuilt to run under nixpkgs Node instead of the broken prebuilt
  # bundle oh-my-openagent provisions into ~/.omo/codegraph. See ./codegraph.
  codegraph = pkgs.callPackage ./codegraph {};
in {
  opencodePlugins = {
    omo.enable = true;
    gsd-sdk.enable = true;
    gsd.enable = true;
    caveman.enable = true;
    claude-token-sync.enable = true;
    superpowers = {
      enable = true;
      skills.enableAll = true;
    };
    mattpocock = {
      # Upstream link-skills.sh excludes "deprecated"; skip it here too.
      # Toggle any group or skill, e.g. `skills.in-progress.enable = false;`
      # or `skills.engineering.tdd = false;` (skill overrides its group).
      enable = true;
      skills = {
        enableAll = false;
        deprecated.enable = false;
        in-progress.enable = false;
        personal.enable = false;
        productivity.enable = true;
        engineering = {
          enable = false;
          improve-codebase-architecture = true;
          to-issues = true;
          to-prd = true;
          prototype = true;
          diagnosing-bugs = true;
          tdd = true;
          domain-modeling = true;
          codebase-design = true;
        };
        misc = {
          enable = false;
          git-guardrails-claude-code = true;
        };
      };
    };
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
        ++ lib.optional config.opencodePlugins.superpowers.enable "./plugins/superpowers/plugin.js"
        ++ [
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
      keybinds = {
        leader = "ctrl+x";
        model_list = "<leader>m";
        session_list = "<leader>l";
        prompt_stash = "<leader>s";
        prompt_stash_pop = "<leader>p";
        # Default binds <leader>s to status_view; free it for stash above.
        status_view = "none";
      };
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

  # oh-my-openagent resolves the codegraph MCP command from $OMO_CODEGRAPH_BIN
  # before anything else, so this overrides the broken prebuilt bundle in
  # ~/.omo/codegraph (whose vendored Node can't run on NixOS) and fixes the
  # `codegraph MCP error -32000: Connection close` error.
  home.sessionVariables.OMO_CODEGRAPH_BIN = lib.getExe codegraph;

  home.packages = [
    pkgs.wakatime-cli
    pkgs.python3Packages.markitdown
    codegraph
  ];
}
