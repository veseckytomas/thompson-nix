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

  opencodeGeminiAuthSrc = pkgs.runCommand "opencode-gemini-auth-src" {} ''
    mkdir -p "$out"
    cp -R ${inputs.opencode-gemini-auth}/. "$out"
    cp ${./lockfiles/gemini-package-lock.json} "$out/package-lock.json"
  '';

  opencodeGeminiAuth = pkgs.buildNpmPackage {
    pname = "opencode-gemini-auth";
    version = "1.4.16";
    src = opencodeGeminiAuthSrc;

    npmDepsHash = "sha256-5j/LIVqCvMYdRYIL4F9wbnWKkkA0UCB1KmK71FWqfaE=";

    nativeBuildInputs = [pkgs.nodejs_22];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
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
  options.opencodePlugins.gemini = {
    enable = lib.mkEnableOption "Gemini auth plugin";
  };

  config = lib.mkIf config.opencodePlugins.gemini.enable {
    xdg.configFile."opencode/opencode-gemini-auth".source = opencodeGeminiAuth;

    opencodePlugins.pluginEntries = ["file:${opencodeConfigDir}/opencode-gemini-auth"];
  };
}
