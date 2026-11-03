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
  cfg = config.opencodePlugins.gsd;

  gsdCoreBuilt = import ./gsd-core-built.nix {inherit pkgs inputs;};

  gsdOpencodePlugin = pkgs.stdenv.mkDerivation {
    pname = "gsd-opencode-plugin";
    version = "unstable";
    src = gsdCoreBuilt;

    nativeBuildInputs = [pkgs.nodejs_22];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      node bin/install.js --opencode --global --config-dir $out --no-sdk
      # v1.8.0 installer omits hooks/*.js guards for --opencode; overlay full source tree.
      cp -R hooks/. $out/hooks/
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      runHook postInstall
    '';
  };

  # Pure-local stdio JSON-RPC shim driving the built mcp-server.cjs (replaces the impure `npx @opengsd/gsd-core gsd-mcp-server`).
  gsdMcpServer = pkgs.writeText "gsd-mcp-server.cjs" ''
    require("${gsdOpencodePlugin}/gsd-core/bin/lib/mcp-server.cjs")
      .runServer({input: process.stdin, output: process.stdout})
      .catch((e) => {
        console.error(e);
        process.exit(1);
      });
  '';
in {
  options.opencodePlugins.gsd = {
    enable = lib.mkEnableOption "GSD (get-shit-done-redux) opencode plugin";
  };

  config = lib.mkIf cfg.enable {
    programs.opencode.settings = {
      permission = {
        read."~/.config/opencode/gsd-core/*" = "allow";
        # Matcher compiles `*` to regex `.*` (dotall), so one star per tree spans any depth.
        external_directory = {
          "~/.config/opencode/gsd-core/*" = "allow";
          "~/.config/opencode/agents/*" = "allow";
          "~/.config/opencode/commands/*" = "allow";
          "~/.config/opencode/hooks/*" = "allow";
          "~/.config/opencode/scripts/*" = "allow";
          # Linux never realpaths before the check, so this only catches callers passing a resolved path.
          "/nix/store/*gsd*" = "allow";
        };
        # Match the stable gsd-tools/gsd_run tokens, not the hash-bearing store path.
        bash = {
          "*gsd-tools*" = "allow";
          "*gsd_run*" = "allow";
        };
      };
      mcp.gsd = {
        type = "local";
        command = ["${lib.getExe pkgs.nodejs_22}" "${gsdMcpServer}"];
        enabled = true;
      };
    };

    home = {
      file.".gsd/defaults.json".text = builtins.toJSON {
        resolve_model_ids = "omit";
      };
      packages = [pkgs.nodejs-slim_24];

      # opencode's plugin sandbox rejects /nix/store symlinks, so gsd-core.js must be a real file in $HOME.
      activation.copyGsdCorePluginEntry = lib.hm.dag.entryAfter ["linkGeneration"] ''
        pluginDir="$HOME/.config/opencode/plugins"
        mkdir -p "$pluginDir"
        rm -f "$pluginDir/gsd-core.js"
        install -m 0644 "${gsdOpencodePlugin}/plugins/gsd-core.js" "$pluginDir/gsd-core.js"
      '';
    };

    xdg.configFile = {
      "opencode/agents" = {
        source = "${gsdOpencodePlugin}/agents";
        recursive = true;
      };
      # Installer emits flat slash-command files under commands/ (plural); opencode scans {command,commands}/**/*.md.
      "opencode/commands" = {
        source = "${gsdOpencodePlugin}/commands";
        recursive = true;
      };
      "opencode/gsd-core" = {
        source = "${gsdOpencodePlugin}/gsd-core";
        recursive = true;
      };
      "opencode/hooks" = {
        source = "${gsdOpencodePlugin}/hooks";
        recursive = true;
      };
      # gsd-core.js require()s scripts/fix-slash-commands.cjs from REPO_ROOT at runtime.
      "opencode/scripts" = {
        source = "${gsdOpencodePlugin}/scripts";
        recursive = true;
      };
      "opencode/gsd-file-manifest.json" = {
        source = "${gsdOpencodePlugin}/gsd-file-manifest.json";
      };
      "opencode/.gsd-profile" = {
        source = "${gsdOpencodePlugin}/.gsd-profile";
      };
      "opencode/gsd-install-state.json" = {
        source = "${gsdOpencodePlugin}/gsd-install-state.json";
      };
    };
  };
}
