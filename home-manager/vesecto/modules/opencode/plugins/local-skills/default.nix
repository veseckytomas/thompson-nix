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
  lib,
  ...
}: let
  cfg = config.opencodePlugins.localSkills;

  # Skills authored and maintained locally in this repo (the "living" skills)
  skillsDir = ./skills;
  skillEntries = builtins.readDir skillsDir;

  # A "skill" is any directory directly under ./skills that holds a SKILL.md.
  # Discover them dynamically so new skills are picked up automatically without
  # editing this file.
  skillNames = builtins.filter (name:
    skillEntries.${name}
    == "directory"
    && builtins.pathExists "${skillsDir}/${name}/SKILL.md")
  (builtins.attrNames skillEntries);

  # Skills selected for installation. Each per-skill toggle defaults to
  # skills.enableAll, so setting `skills.<name> = false` (or true) overrides the
  # bulk default for that single skill.
  enabledSkills = builtins.filter (name: cfg.skills.${name}) skillNames;
in {
  options.opencodePlugins.localSkills = {
    enable = lib.mkEnableOption "locally-authored opencode skills (modules/opencode/skills)";

    skills =
      {
        enableAll = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to install all locally-authored skills. Individual skills
            can override this default via `skills.<name>`.
          '';
        };
      }
      // builtins.listToAttrs (map (name: {
          inherit name;
          value = lib.mkOption {
            type = lib.types.bool;
            default = cfg.skills.enableAll;
            description = ''
              Whether to install the local "${name}" skill. Defaults to
              `skills.enableAll`.
            '';
          };
        })
        skillNames);
  };

  config = lib.mkIf cfg.enable {
    # Each enabled skill is symlinked flat into ~/.config/opencode/skills/<skill>
    # — the directory opencode scans one level deep — matching how the
    # superpowers and mattpocock modules deploy their skills.
    xdg.configFile = builtins.listToAttrs (map (name: {
        name = "opencode/skills/${name}";
        value = {
          source = "${skillsDir}/${name}";
          recursive = true;
        };
      })
      enabledSkills);
  };
}
