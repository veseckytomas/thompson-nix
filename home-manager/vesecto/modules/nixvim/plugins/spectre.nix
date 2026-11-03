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
  programs.nixvim = {
    plugins.spectre = {
      enable = true;
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>sr";
        action.__raw = ''
          function()
            require('spectre').toggle()
          end
        '';
        options.desc = "[S]earch & [R]eplace";
      }
      {
        mode = ["n"];
        key = "<leader>sf";
        action.__raw = ''
          function()
            require("spectre").open_file_search({select_word=true})
          end
        '';
        options.desc = "[S]earch [F]ile";
      }
    ];
  };
}
