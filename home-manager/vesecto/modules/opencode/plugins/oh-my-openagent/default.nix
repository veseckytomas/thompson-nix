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
  cfg = config.opencodePlugins.omo;
  inherit (pkgs.stdenv.hostPlatform) system;
  bun2nix = inputs.bun2nix.packages.${system}.default;

  bunDeps = bun2nix.fetchBunDeps {
    bunNix = ./oh-my-openagent-bun.nix;
  };

  oh-my-openagent = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent";
    version = "4.8.1";

    src = inputs.oh-my-openagent;

    patchPhase = ''
      runHook prePatch

      # Fix isMarkdownFile to accept symlinks. Home-manager installs
      # xdg.configFile entries as symlinks, and Node.js fs.Dirent.isFile()
      # returns false for symlinks, causing agents/commands/skills to be
      # silently skipped by oh-my-openagent's loaders.
      sed -i 's/isFile: () => boolean })/isFile: () => boolean; isSymbolicLink?: () => boolean })/' packages/utils/src/file-utils.ts
      sed -i 's/entry.isFile()/(entry.isFile() || (entry.isSymbolicLink ? entry.isSymbolicLink() : false))/' packages/utils/src/file-utils.ts

      # Fix skill directory loader to not exclude symlinks explicitly
      sed -i '/!entry.isSymbolicLink() &&/d' packages/omo-opencode/src/features/opencode-skill-loader/skill-directory-loader.ts

      # Runtime fallback retries are wrongly rejected by the promptAsync gate
      # because a failed provider leaves an incomplete assistant turn. Bypass the
      # tool-state check for fallback auto-retries so the retry can dispatch.
      sed -i 's/queueBehavior: "defer",/queueBehavior: "defer", checkToolState: false,/g' packages/omo-opencode/src/hooks/runtime-fallback/auto-retry-dispatch.ts

      runHook postPatch
    '';

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      bun2nix.hook
      pkgs.nodejs
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
    ];

    autoPatchelfIgnoreMissingDeps = ["libc.musl-x86_64.so.1"];

    inherit bunDeps;

    bunInstallFlags = ["--linker=hoisted"];

    buildPhase = ''
      runHook preBuild
      bun run build

      # Pre-build the LSP daemon + tools MCP (the `lsp` MCP server, a.k.a.
      # omo-lsp). Upstream's root `build` script omits these — they are built
      # lazily via `npm ci && npm run build` on the first `lsp` MCP launch.
      # Under the read-only Nix store that lazy build cannot write its dist/,
      # so opencode's first connection died with `-32000: Connection closed`
      # and the race recurred after every `home-manager switch`. We compile
      # them here against the already-installed hoisted node_modules (no
      # network / npm ci needed), so the store ships a ready-to-run
      # packages/lsp-daemon/dist/cli.js.
      echo "Pre-building @code-yeongyu/lsp-tools-mcp ..."
      ( cd packages/lsp-tools-mcp && ../../node_modules/.bin/tsc -p tsconfig.build.json )

      # lsp-daemon resolves lsp-tools-mcp via `file:../lsp-tools-mcp`; provide
      # that link explicitly since these packages are not bun workspace members.
      mkdir -p packages/lsp-daemon/node_modules/@code-yeongyu
      ln -sfn ../../../lsp-tools-mcp packages/lsp-daemon/node_modules/@code-yeongyu/lsp-tools-mcp

      echo "Pre-building @code-yeongyu/lsp-daemon ..."
      ( cd packages/lsp-daemon \
          && ../../node_modules/.bin/tsc -p tsconfig.build.json \
          && bun build src/cli.ts src/index.ts --outdir dist --target node --format esm \
          && node scripts/stamp-dist-version.mjs )

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
    home.packages = [oh-my-openagent];

    xdg.configFile = {
      "opencode/oh-my-openagent.json".source = ./oh-my-openagent.json;
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
