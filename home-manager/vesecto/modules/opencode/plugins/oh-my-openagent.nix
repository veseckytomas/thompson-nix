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
  opencodeConfigDir = "${config.home.homeDirectory}/.config/opencode";
  opencodeOhMyOpenAgentDeps = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent-deps";
    version = "4.4.0-dev";
    src = inputs.oh-my-openagent;

    nativeBuildInputs = [pkgs.bun];

    dontConfigure = true;
    dontFixup = true;

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-MZzLQhas31hM2CvHJZXgQZVJQulJUAd5SDiMnv9ZUe4=";

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"

      bun install --frozen-lockfile --ignore-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R node_modules "$out"/

      runHook postInstall
    '';
  };
  opencodeOhMyOpenAgent = pkgs.stdenv.mkDerivation {
    pname = "oh-my-openagent-opencode-plugin";
    version = "4.4.0-dev";
    src = inputs.oh-my-openagent;

    nativeBuildInputs = [
      pkgs.bun
      pkgs.nodejs_22
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      cp -R ${opencodeOhMyOpenAgentDeps}/node_modules ./node_modules
      chmod -R u+w node_modules
      patchShebangs node_modules

      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"

      bun run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R \
        package.json \
        bin \
        dist \
        node_modules \
        .opencode \
        packages \
        assets \
        "$out"/

      runHook postInstall
    '';
  };
in {
  options.opencodePlugins.oh-my-openagent = {
    enable = lib.mkEnableOption "Oh My OpenAgent plugin";
  };

  config = lib.mkIf config.opencodePlugins.oh-my-openagent.enable {
    xdg.configFile."opencode/oh-my-openagent".source = opencodeOhMyOpenAgent;

    home.sessionVariables = {
      OMO_DISABLE_POSTHOG = "1";
      OMO_SEND_ANONYMOUS_TELEMETRY = "0";
    };

    opencodePlugins.pluginEntries = ["file:${opencodeConfigDir}/oh-my-openagent"];
    opencodePlugins.tuiPluginEntries = ["file:${opencodeConfigDir}/oh-my-openagent"];
  };
}
