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
    plugins.snacks = {
      enable = true;
      settings = {
        lazygit.enable = true;
        notifier.enable = true;
        quickfile.enable = true;
        bigfile.enable = true;
        dashboard.enable = true;
        statuscolumn.enable = true;
        input.enable = true;
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>lg";
        action.__raw = ''
          function()
            Snacks.lazygit()
          end
        '';
        options.desc = "Open LazyGit";
      }
    ];
  };
}
