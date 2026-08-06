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
  inputs,
  ...
}: let
  # CodeGraph, rebuilt to run under nixpkgs Node instead of the broken prebuilt
  # bundle oh-my-openagent provisions into ~/.omo/codegraph. See ./codegraph.
  codegraph = pkgs.callPackage ./codegraph {};
  # graphify + graphify-mcp CLIs, built from the pinned uv workspace (uv2nix). See ./graphify.
  graphify = import ./graphify {inherit inputs pkgs;};
  # Google (Antigravity CLI) provider + its agy-auth plugin are kept together so the provider always ships with its auth plugin.
  googleProvider = import ./providers/google.nix;
  # Anthropic provider models + its claude-bridge plugin (native Claude OAuth dropped).
  anthropicProvider = import ./providers/anthropic.nix;
  # Pinned npm plugin versions; bumped to npm-latest by nixos-run update (update-opencode-npm-plugins.sh).
  npmPlugins = builtins.fromJSON (builtins.readFile ./plugins/npm-plugins.json);
in {
  opencodePlugins = {
    omo.enable = true;
    omniroute.enable = true;
    gsd-sdk.enable = true;
    gsd.enable = true;
    caveman.enable = true;
    claude-token-sync.enable = true;
    cache-control-cap.enable = true;
    system-message-hoist.enable = true;
    graphify.enable = true;
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
        engineering = {
          enable = true;
          triage = false;
        };
        in-progress.enable = false;
        misc = {
          enable = false;
          git-guardrails-claude-code = true;
        };
        productivity.enable = true;
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

  opencodeProviders = {
    litellm.enable = false;
    omniroute.enable = true;
    openai.enable = false;
    "google-agy".enable = false;
    anthropic.enable = false;
  };

  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      autoupdate = false;
      lsp = true;
      plugin =
        [
          "./plugins/caveman/plugin.js"
        ]
        ++ lib.optional config.opencodePlugins.omo.enable "./node_modules/oh-my-openagent"
        ++ lib.optional config.opencodePlugins.superpowers.enable "./plugins/superpowers/plugin.js"
        ++ [
          "opencode-wakatime@${npmPlugins."opencode-wakatime"}"
          "./plugins/claude-token-sync/plugin.js"
          # "@slkiser/opencode-quota@${npmPlugins."@slkiser/opencode-quota"}"
        ]
        ++ lib.optional config.opencodeProviders.openai.enable "opencode-openai-multi-auth@${npmPlugins."opencode-openai-multi-auth"}"
        ++ lib.optional config.opencodeProviders."google-agy".enable googleProvider.plugin
        ++ lib.optional config.opencodeProviders.anthropic.enable anthropicProvider.plugin
        ++ lib.optional config.opencodePlugins.cache-control-cap.enable "./plugins/cache-control-cap/plugin.js"
        ++ lib.optional config.opencodePlugins.system-message-hoist.enable "./plugins/system-message-hoist/plugin.js"
        ++ lib.optional config.opencodePlugins.graphify.enable "./plugins/graphify/plugin.js";
      provider =
        lib.optionalAttrs config.opencodeProviders.litellm.enable {litellm = import ./providers/litellm.nix;}
        // lib.optionalAttrs config.opencodeProviders.omniroute.enable {omniroute = import ./providers/omniroute.nix;}
        // lib.optionalAttrs config.opencodeProviders.openai.enable {openai = import ./providers/openai.nix;}
        // lib.optionalAttrs config.opencodeProviders."google-agy".enable {"google-agy" = googleProvider.provider;}
        // lib.optionalAttrs config.opencodeProviders.anthropic.enable {anthropic = anthropicProvider.provider;};
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
        preserve_recent_tokens = 8000;
        reserved = 0;
      };
      mcp = {
        markitdown = {
          type = "local";
          command = ["${pkgs.markitdown-mcp}/bin/markitdown-mcp"];
          enabled = true;
        };
        # Per-project graph server; graphify-mcp loads graphify-out/graph.json lazily, so it is safe with no graph.
        graphify = {
          type = "local";
          command = ["${graphify}/bin/graphify-mcp" "graphify-out/graph.json"];
          enabled = config.opencodePlugins.graphify.enable && config.opencodePlugins.graphify.mcp.enable;
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
      # plugin = ["@slkiser/opencode-quota@${npmPlugins."@slkiser/opencode-quota"}"];
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
  # Overridden by server.nix's oc() when the server module is imported.
  programs.zsh.shellAliases.oc = "opencode";

  imports = [
    ./maintenance.nix
    ./plugins
    ./providers/options.nix
    # ./server.nix
  ];

  # Local "living" skills (./skills) are deployed per-skill by the localSkills
  # module (./plugins/local-skills.nix), mirroring superpowers/mattpocock.
  xdg.configFile = {
    "opencode/opencode-quota/quota-toast.json" = {
      source = ./plugins/opencode-quota.json;
    };
    "opencode/AGENTS.md".text =
      ''
        # GitLab issues

        `glab` is installed and authenticated. Read issue context via bash before
        starting work tied to an issue number or a branch like `123-fix-foo`.

        - View one issue:        glab issue view <id> --comments
        - Issues assigned to me: glab issue list --assignee=@me
        - Search:                glab issue list --search "<text>"
      ''
      + "\n"
      + builtins.readFile (inputs.graphify-src + "/graphify/always_on/agents-md.md");
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
    pkgs.nodejs
    pkgs.gh
    codegraph
    graphify
    pkgs.claude-code
    pkgs.antigravity-cli
  ];
}
