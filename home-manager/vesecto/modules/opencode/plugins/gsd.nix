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
      # gsd-tools surfaces capabilities from <root>/commands/gsd; the opencode installer drops it, so restore it or every skill-backed capability goes inactive.
      mkdir -p "$out/commands"
      cp -R "$src/commands/gsd" "$out/commands/gsd"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      runHook postInstall
    '';
  };
in {
  options.opencodePlugins.gsd = {
    enable = lib.mkEnableOption "GSD (get-shit-done-redux) opencode plugin";
  };

  config = lib.mkIf cfg.enable {
    programs.opencode.settings = {
      permission = {
        read."~/.config/opencode/gsd-core/*" = "allow";
        external_directory."~/.config/opencode/gsd-core/*" = "allow";
        # Match the stable gsd-tools/gsd_run tokens, not the hash-bearing store path.
        bash = {
          "*gsd-tools*" = "allow";
          "*gsd_run*" = "allow";
        };
      };
    };

    home = {
      file.".gsd/defaults.json".text = builtins.toJSON {
        resolve_model_ids = "omit";
      };
      packages = [pkgs.nodejs-slim_24];
    };

    xdg.configFile = {
      "opencode/agents" = {
        source = "${gsdOpencodePlugin}/agents";
        recursive = true;
      };
      "opencode/command" = {
        source = "${gsdOpencodePlugin}/command";
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
