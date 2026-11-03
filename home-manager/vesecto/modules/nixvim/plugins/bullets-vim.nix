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
{...}: {
  programs.nixvim.plugins.bullets = {
    enable = true;
    settings = {
      enable_in_empty_buffers = 0;
      outline_levels = ["ROM" "ABC" "num" "abc" "rom" "std-"];
      enabled_file_types = [
        "markdown"
        "text"
        "gitcommit"
        "scratch"
      ];
    };
    lazyLoad = {
      enable = true;
      settings.ft = [
        "markdown"
      ];
    };
  };
}
