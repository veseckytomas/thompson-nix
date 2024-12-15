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
    plugins.copilot-chat = {
      enable = true;
      lazyLoad = {
        enable = true;
        settings.cmd = "CopilotChat";
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>coc";
        action = "<cmd>CopilotChat<CR>";
        options.desc = "[C][O]pilot [C]hat";
      }
    ];
  };
}
