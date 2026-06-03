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
  src = inputs.get-shit-done-redux;

  rootDeps = pkgs.importNpmLock.buildNodeModules {
    npmRoot = src;
    nodejs = pkgs.nodejs_22;
    derivationArgs = {
      pname = "get-shit-done-redux-root-deps";
      version = "unstable";
    };
  };

  sdkDeps = pkgs.importNpmLock.buildNodeModules {
    npmRoot = "${src}/sdk";
    nodejs = pkgs.nodejs_22;
    derivationArgs = {
      pname = "get-shit-done-redux-sdk-deps";
      version = "unstable";
    };
  };

  getShitDoneRedux = pkgs.stdenv.mkDerivation {
    pname = "get-shit-done-redux";
    version = "unstable";
    inherit src;

    nativeBuildInputs = [
      pkgs.nodejs_22
      pkgs.makeWrapper
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      cp -R ${rootDeps}/node_modules ./node_modules
      chmod -R u+w node_modules
      patchShebangs node_modules

      rm -rf sdk/node_modules
      cp -R ${sdkDeps}/node_modules ./sdk/
      chmod -R u+w sdk/node_modules
      patchShebangs sdk/node_modules

      pushd sdk
      npm run build
      popd

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -R \
        bin \
        commands \
        get-shit-done \
        agents \
        hooks \
        scripts \
        sdk \
        "$out"/

      mkdir -p "$out/bin"
      chmod +x "$out/bin/install.js" "$out/bin/gsd-sdk.js"
      makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/get-shit-done-redux" \
        --add-flags "$out/bin/install.js"
      makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/gsd-sdk" \
        --add-flags "$out/bin/gsd-sdk.js"
      makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/gsd-tools" \
        --add-flags "$out/bin/gsd-sdk.js"

      runHook postInstall
    '';
  };
in {
  options.opencodePlugins.gsd-sdk = {
    enable = lib.mkEnableOption "GSD SDK (get-shit-done-redux CLI tools)";
  };

  config = lib.mkIf config.opencodePlugins.gsd-sdk.enable {
    home.packages = [getShitDoneRedux];
  };
}
