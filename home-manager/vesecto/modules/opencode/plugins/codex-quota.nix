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
  opencodeCodexQuotaDeps = pkgs.importNpmLock.buildNodeModules {
    npmRoot = inputs.opencode-codex-quota;
    nodejs = pkgs.nodejs_22;
    derivationArgs = {
      pname = "opencode-codex-quota-deps";
      version = "1.0.1";
    };
  };
  opencodeCodexQuota = pkgs.stdenv.mkDerivation {
    pname = "opencode-codex-quota";
    version = "1.0.1";
    src = inputs.opencode-codex-quota;

    nativeBuildInputs = [pkgs.nodejs_22];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      cp -R ${opencodeCodexQuotaDeps}/node_modules ./node_modules
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
  options.opencodePlugins.codex-quota = {
    enable = lib.mkEnableOption "OpenAI Codex quota plugin";
  };

  config = lib.mkIf config.opencodePlugins.codex-quota.enable {
    xdg.configFile."opencode/opencode-codex-quota".source = opencodeCodexQuota;

    opencodePlugins.pluginEntries = ["file:${opencodeConfigDir}/opencode-codex-quota"];
  };
}
