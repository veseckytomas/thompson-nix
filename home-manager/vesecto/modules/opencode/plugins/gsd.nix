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
  opencodeGsd =
    pkgs.runCommand "opencode-gsd" {
      nativeBuildInputs = [pkgs.nodejs_22];
    } ''
      mkdir -p "$out" "$TMPDIR/home"
      cp -R ${inputs.get-shit-done-redux} "$TMPDIR/get-shit-done-redux"
      chmod -R u+rwX "$TMPDIR/get-shit-done-redux"

      export HOME="$TMPDIR/home"
      export XDG_CONFIG_HOME="$TMPDIR/home/.config"
      export GSD_SKIP_STALE_SDK_CHECK=1

      ${pkgs.nodejs_22}/bin/node \
        "$TMPDIR/get-shit-done-redux/bin/install.js" \
        --opencode \
        --global \
        --no-sdk \
        --config-dir "$out"

      rm -f "$out/opencode.json"
      rm -f "$out/gsd-file-manifest.json"

      while IFS= read -r -d "" file; do
        substituteInPlace "$file" --replace "$out" "${opencodeConfigDir}"
      done < <(find "$out" -type f -print0)
    '';
in {
  options.opencodePlugins.gsd = {
    enable = lib.mkEnableOption "GSD (Get Shit Done) plugin";
    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
    };
  };

  config = lib.mkIf config.opencodePlugins.gsd.enable {
    opencodePlugins = {
      gsd.package = opencodeGsd;
      gsd-sdk.enable = lib.mkForce true;
      agentSources = ["${opencodeGsd}/agents"];
      commandSources = ["${opencodeGsd}/command"];
    };

    xdg.configFile = {
      "opencode/get-shit-done".source = "${opencodeGsd}/get-shit-done";
      "opencode/hooks".source = "${opencodeGsd}/hooks";
      "opencode/package.json".source = "${opencodeGsd}/package.json";
    };

    programs.opencode.settings.permission = {
      read."${opencodeConfigDir}/get-shit-done/*" = "allow";
      external_directory."${opencodeConfigDir}/get-shit-done/*" = "allow";
    };
  };
}
