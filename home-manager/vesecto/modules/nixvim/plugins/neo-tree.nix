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
    plugins.neo-tree = {
      enable = true;
      settings = {
        enable_git_status = true;
        enable_modified_markers = true;
        enable_refresh_on_write = true;
        close_if_last_window = true;
        filesystem = {
          filtered_items = {
            visible = false;
            show_hidden_count = true;
            hide_dotfiles = false;
            hide_gitignored = false;
            hide_by_name = [
              "node_modules"
              "package-lock.json"
            ];
            never_show = [
              ".git"
              ".mypy_cache"
            ];
          };
        };
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<C-n>";
        action = "<cmd>Neotree toggle reveal left<CR>";
        options.desc = "Toggle Neotree";
      }
    ];
  };
}
