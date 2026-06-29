#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#   / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  pkgs,
  inputs,
}: let
  src = inputs.get-shit-done-redux;

  deps = pkgs.importNpmLock.buildNodeModules {
    npmRoot = src;
    nodejs = pkgs.nodejs_22;
    derivationArgs = {
      pname = "gsd-core-deps";
      version = "unstable";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    pname = "gsd-core-built";
    version = "unstable";
    inherit src;

    nativeBuildInputs = [pkgs.nodejs_22];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      cp -R ${deps}/node_modules ./node_modules
      chmod -R u+w node_modules
      patchShebangs node_modules

      # Compile src/*.cts -> gsd-core/bin/lib/*.cjs (the git-ignored artifacts).
      npm run build:lib

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      # node_modules is only needed for the tsc build above; the runtime entry
      # points (install.js, gsd-tools.cjs) require no npm packages.
      rm -rf node_modules
      rm -f tsconfig.build.tsbuildinfo

      mkdir -p "$out"
      cp -R . "$out"/

      runHook postInstall
    '';
  }
