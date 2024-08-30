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
  programs.nixvim = {
    plugins.spectre = {
      enable = true;
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>sr";
        action.__raw = ''
          require('spectre').toggle()
        '';
        options.desc = "[S]earch & [R]eplace";
      }
    ];
  };
}
