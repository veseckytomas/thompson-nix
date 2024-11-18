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
{system_version, ...}: {
  home = {
    username = "vesecto";
    homeDirectory = "/home/vesecto";
    stateVersion = system_version;
    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  news.display = "silent";
  programs.home-manager.enable = true;

  imports = [
    ./modules
  ];
}
