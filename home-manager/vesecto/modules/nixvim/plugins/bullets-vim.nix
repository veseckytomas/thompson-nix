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
  programs.nixvim.plugins.bullets = {
    enable = true;
    settings = {
      enable_in_empty_buffers = 0;
      bullets_set_mappings = 0;
      bullets_outline_levels = "['ROM', 'ABC', 'num', 'abc', 'rom', 'std-', 'std*', 'std+']";
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
