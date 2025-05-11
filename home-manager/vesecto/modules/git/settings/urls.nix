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
{...}: {
  programs.git.extraConfig = {
    "url \"git@github.com:\"" = {
      insteadOf = "gh:";
    };
    "url \"git@gitlab.com:\"" = {
      insteadOf = "gl:";
    };
    "url \"git@gitlab.com:vesecky.tomas/\"" = {
      insteadOf = "glp:";
    };
    "url \"git@gitlab.fit.cvut.cz:\"" = {
      insteadOf = "fit:";
    };
    "url \"git@gitlab.fit.cvut.cz:vesecto1/\"" = {
      insteadOf = "fitp:";
    };
  };
}
