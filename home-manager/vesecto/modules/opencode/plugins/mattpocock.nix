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
  cfg = config.opencodePlugins.mattpocock;

  src = inputs.mattpocock-skills;
  skillsDir = "${src}/skills";

  # Matt Pocock's repo organises skills into groups: skills/<group>/<skill>/.
  # Discover both groups and the skills inside each group dynamically so new
  # groups/skills are picked up automatically without editing this file. A
  # "skill" is a directory containing a SKILL.md; a "group" is any directory
  # directly under skills/.
  groupEntries = builtins.readDir skillsDir;
  groupNames = builtins.filter (n: groupEntries.${n} == "directory") (builtins.attrNames groupEntries);

  skillsOf = group: let
    dir = "${skillsDir}/${group}";
    entries = builtins.readDir dir;
  in
    builtins.filter
    (n: entries.${n} == "directory" && builtins.pathExists "${dir}/${n}/SKILL.md")
    (builtins.attrNames entries);

  # group -> [ skillName ]
  groupSkills = builtins.listToAttrs (map (g: {
      name = g;
      value = skillsOf g;
    })
    groupNames);

  # (group, skill) pairs selected for installation. A skill is installed when
  # its toggle resolves true. Resolution precedence (most specific wins):
  #   skills.<group>.<skill>  ->  skills.<group>.enable  ->  skills.enableAll
  enabledSkills = builtins.concatMap (g:
    map (s: {
      group = g;
      skill = s;
    })
    (builtins.filter (s: cfg.skills.${g}.${s}) groupSkills.${g}))
  groupNames;
in {
  options.opencodePlugins.mattpocock = {
    enable = lib.mkEnableOption "Matt Pocock's opencode skills (github:mattpocock/skills)";

    skills =
      {
        enableAll = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to install all Matt Pocock skills. Individual groups and
            skills can override this via `skills.<group>.enable` and
            `skills.<group>.<skill>`.
          '';
        };
      }
      // builtins.listToAttrs (map (group: {
          name = group;
          value =
            {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = cfg.skills.enableAll;
                description = ''
                  Whether to install every skill in the "${group}" group.
                  Defaults to `skills.enableAll`. Individual skills in this
                  group override it via `skills.${group}.<skill>`.
                '';
              };
            }
            // builtins.listToAttrs (map (skill: {
                name = skill;
                value = lib.mkOption {
                  type = lib.types.bool;
                  default = cfg.skills.${group}.enable;
                  description = ''
                    Whether to install the "${skill}" skill (group
                    "${group}"). Defaults to `skills.${group}.enable`.
                  '';
                };
              })
              groupSkills.${group});
        })
        groupNames);
  };

  config = lib.mkIf cfg.enable {
    # Each skill is symlinked flat into ~/.config/opencode/skills/<skill> — the
    # directory opencode scans one level deep — matching upstream
    # scripts/link-skills.sh, which links each skill by its basename. All skill
    # names are unique across groups, so flattening is collision-free.
    xdg.configFile = builtins.listToAttrs (map ({
        group,
        skill,
      }: {
        name = "opencode/skills/${skill}";
        value = {
          source = "${skillsDir}/${group}/${skill}";
          recursive = true;
        };
      })
      enabledSkills);
  };
}
