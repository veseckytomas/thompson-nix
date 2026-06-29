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
#
# GSD Core CLI tools (formerly "GSD SDK").
#
# Upstream retired the standalone `sdk/` package (open-gsd migrations
# enh-191-retire-sdk-package / bug-505 / bug-3810) and renamed the project to
# @opengsd/gsd-core. The old `sdk/` build + `gsd-sdk.js` binary no longer exist.
# This module now ships the gsd-core CLI entry points instead:
#   - get-shit-done-redux / gsd-core -> bin/install.js (the installer)
#   - gsd-tools / gsd_run            -> gsd-core/bin/gsd-tools.cjs (workflow CLI)
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  gsdCoreBuilt = import ./gsd-core-built.nix {inherit pkgs inputs;};

  getShitDoneRedux = pkgs.stdenv.mkDerivation {
    pname = "get-shit-done-redux";
    version = "unstable";
    src = gsdCoreBuilt;

    nativeBuildInputs = [pkgs.makeWrapper];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      libexec="$out/libexec/gsd-core"
      mkdir -p "$libexec"
      cp -R . "$libexec"/

      mkdir -p "$out/bin"

      # Installer (renamed upstream to gsd-core; keep the legacy name too).
      makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/gsd-core" \
        --add-flags "$libexec/bin/install.js"
      makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/get-shit-done-redux" \
        --add-flags "$libexec/bin/install.js"

      # Workflow CLI (replaces the retired gsd-sdk.js). gsd-tools.cjs resolves
      # its lib/ relative to its own location, so point node straight at it.
      makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/gsd-tools" \
        --add-flags "$libexec/gsd-core/bin/gsd-tools.cjs"
      makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/gsd_run" \
        --add-flags "$libexec/gsd-core/bin/gsd-tools.cjs"

      runHook postInstall
    '';

    meta = {
      description = "GSD Core CLI tools (installer + workflow tools)";
      mainProgram = "gsd-core";
    };
  };
in {
  options.opencodePlugins.gsd-sdk = {
    enable = lib.mkEnableOption "GSD Core CLI tools (get-shit-done-redux / gsd-core)";
  };

  config = lib.mkIf config.opencodePlugins.gsd-sdk.enable {
    home.packages = [
      getShitDoneRedux
      pkgs.nodejs-slim_24
    ];
  };
}
