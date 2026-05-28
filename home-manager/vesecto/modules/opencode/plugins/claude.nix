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
  opencodeClaudeBridgeDeps = pkgs.importNpmLock.buildNodeModules {
    npmRoot = inputs.opencode-claude-bridge;
    nodejs = pkgs.nodejs_22;
    derivationArgs = {
      pname = "opencode-claude-bridge-deps";
      version = "unstable";
    };
  };
  opencodeClaudeBridge = pkgs.stdenv.mkDerivation {
    pname = "opencode-claude-bridge";
    version = "unstable";
    src = inputs.opencode-claude-bridge;

    nativeBuildInputs = [pkgs.nodejs_22];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      cp -R ${opencodeClaudeBridgeDeps}/node_modules ./node_modules
      chmod -R u+w node_modules
      patchShebangs node_modules

      export HOME="$TMPDIR/home"

      npm run build

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R \
        package.json \
        dist \
        node_modules \
        "$out"/

      runHook postInstall
    '';
  };
in {
  options.opencodePlugins.claude = {
    enable = lib.mkEnableOption "Claude bridge plugin";
  };

  config = lib.mkIf config.opencodePlugins.claude.enable {
    xdg.configFile."opencode/claude-bridge".source = opencodeClaudeBridge;

    opencodePlugins.pluginEntries = ["file:${opencodeConfigDir}/claude-bridge"];
  };
}
