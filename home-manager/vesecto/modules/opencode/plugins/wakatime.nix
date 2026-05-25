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
  opencodeWakatimeDeps = pkgs.stdenv.mkDerivation {
    pname = "opencode-wakatime-deps";
    version = "1.3.8";
    src = inputs.opencode-wakatime;

    nativeBuildInputs = [pkgs.nodejs_22 pkgs.cacert];

    dontConfigure = true;
    dontFixup = true;

    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
    outputHash = "sha256-LH+rlOOF2QjMczVxbj5Lc3LcM4wc4w8dDHc+ExThpRs=";

    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR/home"
      export NODE_EXTRA_CA_CERTS="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

      npm install --frozen-lockfile --ignore-scripts

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R node_modules "$out"/

      runHook postInstall
    '';
  };
  opencodeWakatime = pkgs.stdenv.mkDerivation {
    pname = "opencode-wakatime";
    version = "1.3.8";
    src = inputs.opencode-wakatime;

    nativeBuildInputs = [pkgs.nodejs_22];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      cp -R ${opencodeWakatimeDeps}/node_modules ./node_modules
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
        "$out"/

      runHook postInstall
    '';
  };
in {
  options.opencodePlugins.wakatime = {
    enable = lib.mkEnableOption "WakaTime plugin";
  };

  config = lib.mkIf config.opencodePlugins.wakatime.enable {
    xdg.configFile."opencode/wakatime".source = opencodeWakatime;

    opencodePlugins.pluginEntries = ["file:${opencodeConfigDir}/wakatime"];
  };
}
