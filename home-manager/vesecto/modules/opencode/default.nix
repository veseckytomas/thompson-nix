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
  upstreamGraphifyAgentsMd = inputs.graphify-src + "/graphify/always_on/agents-md.md";
  # Hash guard: a graphify-src bump fails eval loudly instead of silently keeping our divergent copy.
  upstreamGraphifyAgentsMdSha256 = "6a4a2e13159f2d89a9ab83351766e72ab94de06929d80767ac50913e4350e3a5";
  # Replaces upstream's block, which leads with `query` - the costliest scoped command.
  # `query` is a depth-3 BFS that spends its whole token budget: ~6.4KB even for an
  # exact node (AGENTS.md 174 nodes, flake.nix 49), while `explain` is bounded by real
  # degree (237-837B) and `path` costs ~86B. Cost tracks start-node fanout, not phrasing.
  graphifyAgentsMd = ''
    ## graphify

    If `graphify-out/graph.json` exists, start codebase questions with Graphify.

    - `/graphify`: load the `graphify` skill first.
    - Prefer the `graphify` MCP server over the CLI, and pick the narrowest tool:
      known target -> `GetNode`/`GetNeighbors`; two nodes -> `ShortestPath`;
      orientation -> `GraphStats`/`GodNodes`/`GetCommunity`; only genuinely
      open-ended exploration -> `QueryGraph`.
    - Name the exact indexed label. Matching is lexical, not semantic, so a prose
      question can land on an unrelated same-named node and return its whole fanout.
    - On broad or truncated output, narrow the label/depth/`context_filter` before
      raising `token_budget` - the budget caps output, it cannot fix a wrong start node.
    - Reserve `GRAPH_REPORT.md` for whole-repo review. Use the CLI only if MCP is down.
    - A git-dirty `graphify-out/` is still usable. After code changes: `graphify update .`
  '';
  # Google (Antigravity CLI) provider + its agy-auth plugin are kept together so the provider always ships with its auth plugin.
  googleProvider = import ./providers/google.nix;
  # Anthropic provider models + its claude-bridge plugin (native Claude OAuth dropped).
  anthropicProvider = import ./providers/anthropic.nix;
  # Pinned npm plugin versions; bumped to npm-latest by nixos-run update (update-opencode-npm-plugins.sh).
  npmPlugins = builtins.fromJSON (builtins.readFile ./plugins/npm-plugins.json);
  gnupgTools = pkgs.callPackage ../gnupg/tools.nix {};
  context7Recipient = "98E1DB9E7A724AC5FC137B1568989091534ED547";
  context7KeyPath = "${config.home.homeDirectory}/.config/api_keys/context7_api_key.gpg";
  # `error` is a tripwire: fail loudly if this key ever moves to the Yubikey.
  context7Decrypt = "${gnupgTools.gpg-decrypt-hardened}/bin/gpg-decrypt-hardened --pinentry error";
  sessionListAll = pkgs.callPackage ./sessions-cli.nix {};
  # opencode's subcommand tree is compiled in, so the wrapper is the only place a `session list-all` can exist.
  sessionListAllGuard = ''
    if [ "$1" = "session" ] && [ "$2" = "list-all" ]; then
      shift 2
      exec ${sessionListAll}/bin/opencode-session-list-all "$@"
    fi
  '';
  # An unset var renders the header as a bare "Bearer", which Context7 rejects outright -
  # unlike sending no header at all, so a missing key BREAKS the server, it does not degrade it.
  context7Prelude = ''
    if [ -r "${context7KeyPath}" ]; then
      __c7="$(${context7Decrypt} "${context7KeyPath}" 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '\r\n' || true)"
      if [ -n "$__c7" ]; then
        export CONTEXT7_API_KEY="$__c7"
      else
        echo "opencode: context7 key failed to decrypt - the context7 MCP server will reject every call" >&2
      fi
      unset __c7
    else
      echo "opencode: context7 key not readable - the context7 MCP server will reject every call" >&2
    fi
  '';
  # Must stay pkgs.opencode; config.programs.opencode.package would recurse infinitely.
  opencodeBase = pkgs.opencode;
  opencodeMainProgram = opencodeBase.meta.mainProgram or "opencode";
  # symlinkJoin drops meta/passthru, which the upstream module dereferences for extraPackages.
  opencodeWithContext7 = pkgs.symlinkJoin {
    name = "opencode-context7";
    paths = [opencodeBase];
    preferLocalBuild = true;
    nativeBuildInputs = [pkgs.makeWrapper];
    # Wrap the upstream path, never the joined symlink: wrapProgram would rename it to .opencode-wrapped_, and `exec -a` cannot mask that from argv[0] because upstream's bin/opencode is a shebang script.
    postBuild = ''
      rm $out/bin/${opencodeMainProgram}
      makeWrapper ${opencodeBase}/bin/${opencodeMainProgram} $out/bin/${opencodeMainProgram} \
        --run ${lib.escapeShellArg sessionListAllGuard} \
        --run ${lib.escapeShellArg context7Prelude}
    '';
    passthru = opencodeBase.passthru or {};
    meta = opencodeBase.meta // {mainProgram = opencodeMainProgram;};
  };
  context7KeyCheck = pkgs.writeShellApplication {
    name = "context7-key-check";
    runtimeInputs = [pkgs.gnupg pkgs.curl pkgs.coreutils];
    text = ''
      endpoint="https://mcp.context7.com/mcp"
      body='{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"resolve-library-id","arguments":{"query":"react hooks","libraryName":"react"}}}'
      probe() {
        if [ "$#" -eq 1 ]; then
          curl -sS -X POST "$endpoint" \
            -H 'Accept: application/json, text/event-stream' \
            -H 'Content-Type: application/json' \
            -H "Authorization: Bearer $1" \
            --data "$body"
        else
          curl -sS -X POST "$endpoint" \
            -H 'Accept: application/json, text/event-stream' \
            -H 'Content-Type: application/json' \
            --data "$body"
        fi
      }
      fail=0
      case "$(probe)" in
        *"/reactjs/react.dev"*) echo "ok   anonymous: endpoint live, returns library data" ;;
        *)
          echo "FAIL anonymous: no library data - endpoint or contract changed"
          fail=1
          ;;
      esac
      case "$(probe ctx7sk-00000000-0000-0000-0000-000000000000)" in
        *"Invalid API key"*) echo "ok   bogus key: rejected - the auth oracle is live" ;;
        *)
          echo "FAIL bogus key: expected 'Invalid API key' body"
          fail=1
          ;;
      esac
      key="$(${context7Decrypt} "${context7KeyPath}" | tr -d '\r\n')"
      if [ "''${#key}" -lt 20 ]; then
        echo "FAIL local key: decrypted value missing or implausibly short"
        exit 1
      fi
      real="$(probe "$key")"
      unset key
      case "$real" in
        *"Invalid API key"*)
          echo "FAIL real key: server rejected it"
          fail=1
          ;;
        *"/reactjs/react.dev"*) echo "ok   real key: accepted, library data returned" ;;
        *)
          echo "FAIL real key: no library data in response"
          fail=1
          ;;
      esac
      case "$(probe "")" in
        *"Invalid API key"*) echo "note empty bearer REJECTED: an unset CONTEXT7_API_KEY would BREAK context7, not degrade it" ;;
        *) echo "note empty bearer tolerated: an unset CONTEXT7_API_KEY degrades to anonymous" ;;
      esac
      exit "$fail"
    '';
  };
in {
  opencodePlugins = {
    omo.enable = true;
    omniroute.enable = true;
    gsd-sdk.enable = true;
    gsd.enable = true;
    caveman.enable = false;
    claude-token-sync.enable = false;
    cache-control-cap.enable = false;
    system-message-hoist.enable = false;
    graphify.enable = true;
    session-list-all.enable = true;
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
        engineering.enable = true;
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
    package = opencodeWithContext7;
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
          # "./plugins/claude-token-sync/plugin.js"
          # "@slkiser/opencode-quota@${npmPlugins."@slkiser/opencode-quota"}"
        ]
        ++ lib.optional config.opencodeProviders.openai.enable "opencode-openai-multi-auth@${npmPlugins."opencode-openai-multi-auth"}"
        ++ lib.optional config.opencodeProviders."google-agy".enable googleProvider.plugin
        ++ lib.optional config.opencodeProviders.anthropic.enable anthropicProvider.plugin
        ++ lib.optional config.opencodePlugins.cache-control-cap.enable "./plugins/cache-control-cap/plugin.js"
        ++ lib.optional config.opencodePlugins.system-message-hoist.enable "./plugins/system-message-hoist/plugin.js"
        ++ lib.optional config.opencodePlugins.graphify.enable "./plugins/graphify/plugin.js"
        ++ lib.optional config.opencodePlugins.session-list-all.enable "./plugins/session-list-all/plugin.js";
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
        # Matcher is regex, not glob: `*` crosses `/`, so a `**/` prefix never matches a top-level file.
        read = {
          "*.env" = "deny";
          "*.env.*" = "deny";
          "*.env.example" = "allow";
          "*.env.sample" = "allow";
          "*.gpg" = "deny";
          "*.jks" = "deny";
          "*.key" = "deny";
          "*.keystore" = "deny";
          "*.netrc" = "deny";
          "*.npmrc" = "deny";
          "*.p12" = "deny";
          "*.p8" = "deny";
          "*.pem" = "deny";
          "*.pfx" = "deny";
          "*credentials.json" = "deny";
          "*id_dsa" = "deny";
          "*id_dsa.pub" = "deny";
          "*id_ecdsa" = "deny";
          "*id_ecdsa.pub" = "deny";
          "*id_ed25519" = "deny";
          "*id_ed25519.pub" = "deny";
          "*id_rsa" = "deny";
          "*id_rsa.pub" = "deny";
        };
        # A repo-local user.name/email outranks the global one, so commits land as a bot.
        edit = {
          "*.git/config" = "deny";
        };
        bash = let
          # Last match wins, so the denies must render after the glab/gsd allows.
          afterAllows = lib.hm.dag.entryAfter ["glab *" "*gsd-tools*" "*gsd_run*"];
          # ...and the `pass ls` carve-out after the pass denies it reopens.
          afterPassDenies = lib.hm.dag.entryAfter ["pass *" "*/pass *"];
        in {
          "glab *" = "allow";
          "*.env*" = afterAllows "deny";
          "*.gpg*" = afterAllows "deny";
          # Trailing " *" compiles to an optional arg group, keeping `jq '.key' x.json` allowed.
          "*.key *" = afterAllows "deny";
          "*.netrc*" = afterAllows "deny";
          "*.npmrc*" = afterAllows "deny";
          "*.p12*" = afterAllows "deny";
          "*.pem *" = afterAllows "deny";
          "*.pfx*" = afterAllows "deny";
          "*credentials.json*" = afterAllows "deny";
          "*id_dsa*" = afterAllows "deny";
          "*id_ecdsa*" = afterAllows "deny";
          "*id_ed25519*" = afterAllows "deny";
          "*id_rsa*" = afterAllows "deny";
          # `pass show X` prints a live secret; only entry listing stays allowed.
          # `*/pass *` closes the absolute-path bypass; the allows must land last.
          "pass *" = afterAllows "deny";
          "*/pass *" = afterAllows "deny";
          "pass ls *" = afterPassDenies "allow";
          "*/pass ls *" = afterPassDenies "allow";
          # `ask`, not `deny`: the glob cannot tell a `--get` read from an identity write.
          "*config*user.email*" = afterAllows "ask";
          "*config*user.name*" = afterAllows "ask";
        };
      };
      # reserved leaves headroom to compact before a chain's real floor (min 128k).
      compaction = {
        auto = true;
        prune = true;
        tail_turns = 2;
        preserve_recent_tokens = 8000;
        reserved = 32000;
      };
      # Cap per-call tool payloads so truncated previews stay small in context.
      tool_output = {
        max_lines = 800;
        max_bytes = 16384;
      };
      mcp = {
        # Remote transport keeps the key out of argv and avoids an impure npx fetch.
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
          enabled = true;
          headers = {
            Authorization = "Bearer {env:CONTEXT7_API_KEY}";
          };
        };
        markitdown = {
          type = "local";
          command = ["${pkgs.markitdown-mcp}/bin/markitdown-mcp"];
          enabled = false;
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
      # TUI plugins render into sidebar slots; `settings.plugin` has no render hook.
      plugin =
        lib.optional config.opencodePlugins.omo.enable
        "${config.home.homeDirectory}/.config/opencode/node_modules/oh-my-openagent/dist/tui.js";

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
        # Background tasks

        Before claiming a task done, settle every background task you launched:
        silence is not proof of life (interrupts/resumes kill tasks silently).
        Probe with `background_output(block=false, full_session=true)`: `completed`
        = collect it; `running` with advancing timestamps = wait for the
        notification; anything else = dead, relaunch or drop the claim. Re-probe
        after any interrupt; name surviving ids explicitly. End every message with
        a one-line count, zero included: "2 background tasks running."

        Stalled is not running. A task still showing `running` past ~30-40 min
        needs progress evidence, not faith: the `Last tool` field must advance
        between probes and a promised target file's mtime must move. Same last
        tool + untouched target = cancel that one id (`background_cancel`,
        never `all=true`) and redo the work inline yourself. Do not keep
        waiting (a running task cannot accept new prompts, so nudging is not an
        option) and do not blindly relaunch the same brief - it can re-hang the
        same way.

        # GitLab issues

        `glab` is installed and authenticated. Read issue context via bash before
        starting work tied to an issue number or a branch like `123-fix-foo`.

        - View one issue:        glab issue view <id> --comments
        - Issues assigned to me: glab issue list --assignee=@me
        - Search:                glab issue list --search "<text>"

        # Library docs

        Reach for `context7` before webfetch/websearch on any library,
        framework, SDK, CLI or cloud service: `resolve-library-id`, then
        `query-docs` with one concept per call. It is indexed and version-aware,
        so prefer it over reading sources off raw.githubusercontent.com or a
        docs site - even for libraries you think you know, since training data
        lags releases. Fall back to webfetch only once context7 has no entry or
        returns nothing usable. Not for this repo's own code (graphify/grep),
        general programming concepts, or debugging business logic.
      ''
      + "\n"
      + (
        # Inlined, not a let-binding: an unreferenced guard is never forced and no-ops silently.
        if builtins.hashFile "sha256" upstreamGraphifyAgentsMd == upstreamGraphifyAgentsMdSha256
        then graphifyAgentsMd
        else
          throw ''
            graphify: upstream always_on/agents-md.md changed (now ${builtins.hashFile "sha256" upstreamGraphifyAgentsMd}).
            Reconcile graphifyAgentsMd in ${toString ./default.nix} with the new upstream text, then update upstreamGraphifyAgentsMdSha256.
          ''
      );
  };

  home = {
    # oh-my-openagent resolves the codegraph MCP command from $OMO_CODEGRAPH_BIN
    # before anything else, so this overrides the broken prebuilt bundle in
    # ~/.omo/codegraph (whose vendored Node can't run on NixOS) and fixes the
    # `codegraph MCP error -32000: Connection close` error.
    sessionVariables.OMO_CODEGRAPH_BIN = lib.getExe codegraph;

    # Keyring-gated so a fresh machine can still activate before the secret key is imported.
    activation.context7KeyAssertion = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if ${pkgs.gnupg}/bin/gpg --batch --list-secret-keys ${context7Recipient} >/dev/null 2>&1; then
        c7key="$(${context7Decrypt} "${context7KeyPath}" 2>/dev/null | ${pkgs.coreutils}/bin/tr -d '\r\n' || true)"
        if [ "''${#c7key}" -lt 20 ]; then
          echo "context7: key at ${context7KeyPath} is missing, empty or corrupt" >&2
          exit 1
        fi
        unset c7key
      else
        echo "context7: secret key absent from this keyring - skipping key assertion" >&2
      fi
    '';

    packages = [
      pkgs.wakatime-cli
      pkgs.python3Packages.markitdown
      pkgs.worktrunk
      pkgs.nodejs
      pkgs.gh
      codegraph
      graphify
      pkgs.claude-code
      pkgs.codex
      pkgs.github-copilot-cli
      pkgs.antigravity-cli
      context7KeyCheck
    ];
  };
}
