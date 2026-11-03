#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.opencodePlugins.superpowers;

  superpowersSrc = inputs.superpowers;

  # Dynamically discover all skill directories in the superpowers repo so new
  # skills are picked up automatically without editing this file.
  skillsDir = "${superpowersSrc}/skills";
  skillEntries = builtins.readDir skillsDir;
  skillNames = builtins.filter (name: (builtins.getAttr name skillEntries) == "directory") (builtins.attrNames skillEntries);

  # Skills selected for installation. Each per-skill toggle defaults to
  # skills.enableAll, so setting `skills.<name> = false` (or true) overrides the
  # bulk default for that single skill.
  enabledSkills = builtins.filter (name: cfg.skills.${name}) skillNames;

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
  options.opencodePlugins.superpowers = {
    enable = lib.mkEnableOption "Superpowers opencode plugin";

    skills =
      {
        enableAll = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to install all Superpowers skills. Individual skills can
            override this default via `skills.<name>`.
          '';
        };
      }
      // builtins.listToAttrs (map (name: {
          inherit name;
          value = lib.mkOption {
            type = lib.types.bool;
            default = cfg.skills.enableAll;
            description = ''
              Whether to install the Superpowers "${name}" skill. Defaults to
              `skills.enableAll`.
            '';
          };
        })
        skillNames);
  };

  config = lib.mkIf cfg.enable {
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
        enabledSkills);
  };
}
