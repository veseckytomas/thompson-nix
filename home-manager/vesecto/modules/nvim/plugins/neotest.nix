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
        key = "<leader>cts";
        action = "<cmd>lua require('neotest').run.run()<CR>";
        options.desc = "[C]ode [T]est [S]ingle";
      }
      {
        mode = ["n"];
        key = "<leader>ctf";
        action = "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<CR>";
        options.desc = "[C]ode [T]est [F]ile";
      }
    ];
  };
}
