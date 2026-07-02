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
    localSkills = {
      # Skills authored locally in ./skills. Discovered dynamically; toggle any
      # one with `skills.<name> = false;` (or set `skills.enableAll = false;`
      # and opt individual skills back in with `skills.<name> = true;`).
      enable = true;
      skills.enableAll = true;
    };
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      autoupdate = false;
      lsp = true;
      model = "litellm/kimi-k2.7";
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
            deepseek-v4-pro = {
              name = "deepseek-v4-pro";
            };
            deepseek-v4-pro-thinking = {
              name = "deepseek-v4-pro-thinking";
            };
            glm-5 = {
              name = "glm-5";
            };
            "kimi-k2.7" = {
              name = "kimi-k2.7";
            };
            "qwen3.5" = {
              name = "qwen3.5";
            };
          };
        };
      };
      permission = {
        external_directory = {
          "/tmp/**" = "allow";
        };
        bash = {
          "glab *" = "allow";
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
      command = {
        issue = {
          description = "Pull a GitLab issue into context";
          template = ''
            GitLab issue $ARGUMENTS:
            !`glab issue view $ARGUMENTS --comments`

            Summarize it and list what needs doing.
          '';
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

  # Local "living" skills (./skills) are deployed per-skill by the localSkills
  # module (./plugins/local-skills.nix), mirroring superpowers/mattpocock.
  xdg.configFile = {
    "opencode/opencode-quota/quota-toast.json" = {
      source = ./plugins/opencode-quota.json;
    };
    "opencode/AGENTS.md".text = ''
      # GitLab issues

      `glab` is installed and authenticated. Read issue context via bash before
      starting work tied to an issue number or a branch like `123-fix-foo`.

      - View one issue:        glab issue view <id> --comments
      - Issues assigned to me: glab issue list --assignee=@me
      - Search:                glab issue list --search "<text>"
    '';
  };

  # oh-my-openagent resolves the codegraph MCP command from $OMO_CODEGRAPH_BIN
  # before anything else, so this overrides the broken prebuilt bundle in
  # ~/.omo/codegraph (whose vendored Node can't run on NixOS) and fixes the
  # `codegraph MCP error -32000: Connection close` error.
  home.sessionVariables.OMO_CODEGRAPH_BIN = lib.getExe codegraph;

  home.packages = [
    pkgs.wakatime-cli
    pkgs.python3Packages.markitdown
    pkgs.worktrunk
    pkgs.nodejs-slim
    codegraph
  ];
}
