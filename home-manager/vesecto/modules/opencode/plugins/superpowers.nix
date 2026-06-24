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
  inputs,
  lib,
  pkgs,
  ...
}: let
  superpowersSrc = inputs.superpowers;

  # Dynamically discover all skill directories in the superpowers repo so new
  # skills are picked up automatically without editing this file.
  skillsDir = "${superpowersSrc}/skills";
  skillEntries = builtins.readDir skillsDir;
  skillNames = builtins.filter (name: (builtins.getAttr name skillEntries) == "directory") (builtins.attrNames skillEntries);

  # Local copy of the superpowers plugin entry point.
  # When installed at ~/.config/opencode/plugins/superpowers/plugin.js,
  # path.resolve(__dirname, '../../skills') inside the plugin resolves to
  # ~/.config/opencode/skills/, which is where we symlink all superpowers
  # skill directories.  This makes the bootstrap message injection and the
  # config hook work from the local copy just like the npm/git install.
  superpowersPlugin = pkgs.runCommand "superpowers-opencode-plugin" {} ''
    mkdir -p $out
    cp ${superpowersSrc}/.opencode/plugins/superpowers.js $out/plugin.js
  '';
in {
  # Plugin entry point loaded as a local plugin by opencode.
  xdg.configFile =
    {
      "opencode/plugins/superpowers" = {
        source = superpowersPlugin;
        recursive = true;
      };
    }
    // builtins.listToAttrs (map (name: {
        name = "opencode/skills/${name}";
        value = {
          source = "${skillsDir}/${name}";
          recursive = true;
        };
      })
      skillNames);
}
