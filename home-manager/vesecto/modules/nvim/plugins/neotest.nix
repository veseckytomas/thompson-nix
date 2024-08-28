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
    plugins.neotest = {
      enable = true;
      adapters = {
        bash.enable = true;
        python.enable = true;
        rust.enable = true;
      };
      settings = {
        output = {
          enabled = true;
          open_on_run = true;
        };
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>gt";
        action = "<cmd>Neogit<CR>";
        options.desc = "[G]it s[t]atus";
      }
    ];
  };
}
