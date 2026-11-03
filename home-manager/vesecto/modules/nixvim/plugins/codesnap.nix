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
    plugins.codesnap = {
      enable = true;
      settings = {
        bg_color = "#535c68";
        watermark = "";
        has_line_number = false;
        mac_window_bar = false;
        save_path = "$HOME/Pictures/Screenshots/Codesnap";
      };
      lazyLoad = {
        enable = true;
        settings = {
          cmd = "CodeSnapSave";
          keys = ["<leader>cs"];
        };
      };
    };
    keymaps = [
      {
        mode = ["v"];
        key = "<leader>cs";
        action = "<cmd>CodeSnapSave<CR>";
        options.desc = "[C]odesnap [S]ave";
      }
    ];
  };
}
