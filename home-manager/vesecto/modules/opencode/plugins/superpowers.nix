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
  ...
}: let
  opencodeConfigDir = "${config.home.homeDirectory}/.config/opencode";
in {
  options.opencodePlugins.superpowers = {
    enable = lib.mkEnableOption "Superpowers plugin";
  };

  config = lib.mkIf config.opencodePlugins.superpowers.enable {
    xdg.configFile."opencode/superpowers".source = inputs.superpowers;

    opencodePlugins.pluginEntries = ["${opencodeConfigDir}/superpowers"];
  };
}
