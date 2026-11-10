#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.opencodePlugins.omo;
  inherit (pkgs.stdenv.hostPlatform) system;
  bun2nix = inputs.bun2nix.packages.${system}.default;

  # fetchBunDeps callPackages bunNix with a fixed attrset, so the workspace source
  # is forwarded through this wrapper instead of being refetched by a pinned rev.
  bunNix = {
    copyPathToStore,
    fetchFromGitHub,
    fetchgit,
    fetchurl,
    ...
  } @ args:
    import ./oh-my-openagent-bun.nix (args // {ohMyOpenagentSrc = inputs.oh-my-openagent;});

  bunDeps = bun2nix.fetchBunDeps {inherit bunNix;};

  oh-my-openagent = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent";
    version = "unstable";

    src = inputs.oh-my-openagent;

    # Default fuzz 2 lets a hunk apply against drifted context and still succeed.
    # An offset is not fuzz, so suppressing its .orig backup keeps -F0 strict.
    patchFlags = ["-p1" "-F0" "--no-backup-if-mismatch"];

    # Every edit below must fail the build if upstream moves its anchor: silent
    # no-ops previously dropped a fix for months without any build signal.
    patches = [
      # Live via delegate-task/category-resolver, which is behind no fallback gate.
      ./fallback-chain-honour-empty-optout.patch
    ];

    postPatch = ''
      # Two of upstream's build nodes reach `npm ci`, which the sandbox has no network for.
      # Anchored on the declaration, not a context diff: the node list drifts every bump.
      substituteInPlace script/build-nodes.ts \
        --replace-fail 'export const BUILD_PROFILES: Record<string, readonly string[]> = {' 'const NIX_EXCLUDED_NODES: readonly string[] = ["codex-plugin", "senpi-plugin"]

      export const BUILD_PROFILES: Record<string, readonly string[]> = {
      	nix: BUILD_NODES.map((node) => node.id).filter((id) => !NIX_EXCLUDED_NODES.includes(id)),'

      # isMarkdownFile drops Home Manager's symlinked agents/commands,
      # because Node's fs.Dirent.isFile() is false for a symlink.
      substituteInPlace packages/utils/src/file-utils.ts \
        --replace-fail 'isFile: () => boolean })' 'isFile: () => boolean; isSymbolicLink?: () => boolean })' \
        --replace-fail 'entry.isFile()' '(entry.isFile() || (entry.isSymbolicLink ? entry.isSymbolicLink() : false))'

      # A failed/hung provider leaves an incomplete assistant turn, so the promptAsync
      # gate rejects the fallback retry that is supposed to rescue it.
      substituteInPlace packages/omo-opencode/src/hooks/runtime-fallback/auto-retry-dispatch.ts \
        --replace-fail 'mode: "async",' 'mode: "async", checkStatus: false, checkToolState: false,'

      # Inheriting the agent's variant yields invalid ids like anthropic/claude-opus-4-7(max).
      substituteInPlace packages/omo-opencode/src/hooks/runtime-fallback/retry-model-payload.ts \
        --replace-fail 'const variant = parsedModel.variant ?? agentSettings?.variant ?? loweredReasoning.variant' 'const variant = parsedModel.variant'

      # `npm ci` needs network; each package's own `npm run build` is offline-capable.
      substituteInPlace package.json \
        --replace-fail 'npm --prefix packages/lsp-tools-mcp ci && ' "" \
        --replace-fail 'npm --prefix packages/lsp-daemon ci && ' ""

      # materialize-shared-upstreams shells out to `git submodule update --init`, but the
      # sandbox has no git and no .git dir; the flake input already carries the submodules.
      substituteInPlace packages/omo-codex/plugin/scripts/materialize-shared-upstreams.mjs \
        --replace-fail 'function initSubmodules({ strict }) {' 'function initSubmodules({ strict }) { return true;'

      # Counted and fail-loud, so it can never silently no-op the way a bare sed would.
      python3 ${./strip-senpi.py} .

      # Upstream's lock resolves senpi, whose packuments the tarball-only offline cache lacks; this one is regenerated against the stripped manifests by the updater.
      cp --no-preserve=mode ${./oh-my-openagent-bun.lock} bun.lock
    '';

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      bun2nix.hook
      pkgs.nodejs
      pkgs.perl
      pkgs.python3
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
      # pi-tui's x11 prebuild arrived with this bump and is the only consumer.
      pkgs.libxcb
    ];

    autoPatchelfIgnoreMissingDeps = ["libc.musl-x86_64.so.1"];

    inherit bunDeps;

    bunInstallFlags = ["--linker=hoisted"];

    # bun2nix's lifecycle phase runs the root `prepare` (`bun run build`) before buildPhase, so the profile must be derivation-wide or that run takes the full 16-node graph into `npm ci`.
    OMO_BUILD_PROFILE = "nix";

    buildPhase = ''
      runHook preBuild

      # The two LSP packages are not bun workspace members, so their own `npm run
      # build` finds neither tsc nor bun in a local node_modules/.bin.
      export PATH="$PWD/node_modules/.bin:$PATH"

      # Building the LSP dists here rather than at first launch: the lazy build
      # cannot write dist/ under the read-only store, which made opencode's first
      # `lsp` connection die with `-32000: Connection closed` after every switch.
      bun run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp package.json postinstall.mjs $out/
      cp -R dist bin node_modules .opencode .agents packages $out/

      chmod +x $out/bin/oh-my-opencode.js

      ln -s oh-my-opencode.js $out/bin/oh-my-openagent
      ln -s oh-my-opencode.js $out/bin/oh-my-opencode
      ln -s oh-my-opencode.js $out/bin/omo
      ln -s oh-my-opencode.js $out/bin/lazycodex

      runHook postInstall
    '';

    meta = {
      description = "Oh My OpenAgent opencode plugin";
      homepage = "https://github.com/code-yeongyu/oh-my-openagent";
      license = pkgs.lib.licenses.unfree;
      platforms = pkgs.lib.platforms.linux;
    };
  };
in {
  options.opencodePlugins.omo.enable = lib.mkEnableOption "Oh My OpenAgent opencode plugin";

  config = lib.mkIf cfg.enable {
    home = {
      packages = [oh-my-openagent];

      # The loader reads only ~/.omo/omo.jsonc now; its `_migrations` list must name every
      # upstream migration id, or a `replace-target` one rewrites this read-only store symlink.
      file.".omo/omo.jsonc".source = ./omo.jsonc;
    };

    # oh-my-openagent bundles a full node_modules (~16.8k files). Symlinking it
    # file-by-file via `recursive = true` — twice, for the oh-my-openagent and
    # oh-my-opencode copies — produced ~33.7k symlinks (81% of every
    # home-manager-managed file) and dominated `home-manager switch` time.
    #
    # Instead we provision both copies here with whole-directory symlinks for
    # the bulk (a few dozen entries each) and keep only the three
    # sandbox-critical files as real files.
    #
    # OpenCode's plugin sandbox realpath-rejects entries that resolve outside
    # the plugin directory, i.e. into /nix/store. So package.json,
    # dist/index.js and postinstall.mjs MUST be real files in $HOME; everything
    # else may symlink into the store. These paths are deliberately NOT managed
    # by xdg.configFile, so home-manager never collides with the real files we
    # write here (which previously caused "in the way" warnings every switch).
    home.activation.installOmoPlugin = lib.hm.dag.entryAfter ["linkGeneration"] ''
      installOmoCopy() {
        local target="$1"
        rm -rf "$target"
        mkdir -p "$target/dist"

        # Bulk package subdirectories: one whole-directory symlink each.
        local sub
        for sub in node_modules packages bin .opencode .agents; do
          ln -s "${oh-my-openagent}/$sub" "$target/$sub"
        done

        # dist: symlink every entry into the store except index.js, which the
        # sandbox requires to be a real file.
        local entry name
        for entry in "${oh-my-openagent}"/dist/*; do
          [ -e "$entry" ] || continue
          name="$(basename "$entry")"
          if [ "$name" = "index.js" ]; then continue; fi
          ln -s "$entry" "$target/dist/$name"
        done

        # Sandbox-critical real files.
        install -m 0644 "${oh-my-openagent}/dist/index.js"   "$target/dist/index.js"
        install -m 0644 "${oh-my-openagent}/package.json"    "$target/package.json"
        install -m 0644 "${oh-my-openagent}/postinstall.mjs" "$target/postinstall.mjs"
      }

      installOmoCopy "$HOME/.config/opencode/node_modules/oh-my-openagent"
      installOmoCopy "$HOME/.config/opencode/node_modules/oh-my-opencode"
    '';
  };
}
