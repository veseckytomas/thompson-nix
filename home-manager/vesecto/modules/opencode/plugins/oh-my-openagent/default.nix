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
      "opencode/node_modules/oh-my-openagent" = {
        source = oh-my-openagent;
        recursive = true;
      };

      "opencode/node_modules/oh-my-opencode" = {
        source = oh-my-openagent;
        recursive = true;
      };

      "opencode/oh-my-openagent.json".source = ./oh-my-openagent.json;
    };

    # OpenCode's plugin sandbox rejects server entries that resolve outside
    # the plugin directory via realpath. home-manager creates every file as
    # a symlink into /nix/store, so the resolved paths are "outside".
    # We copy the critical entry-point files as real files after linkGeneration.
    #
    # `rm -f` handles all prior states: home-manager symlink (first switch),
    # read-only 0444 regular file (copied from Nix store on a previous switch),
    # or missing. `install -m 0644` then writes a fresh owner-writeable copy
    # so future activations can replace it idempotently.
    home.activation.copyOmoPluginEntry = lib.hm.dag.entryAfter ["linkGeneration"] ''
      omoDir="$HOME/.config/opencode/node_modules/oh-my-openagent"
      mkdir -p "$omoDir/dist"
      rm -f "$omoDir/package.json" \
            "$omoDir/dist/index.js" \
            "$omoDir/postinstall.mjs"
      install -m 0644 "${oh-my-openagent}/package.json"     "$omoDir/package.json"
      install -m 0644 "${oh-my-openagent}/dist/index.js"    "$omoDir/dist/index.js"
      install -m 0644 "${oh-my-openagent}/postinstall.mjs"  "$omoDir/postinstall.mjs"
    '';
  };
}
