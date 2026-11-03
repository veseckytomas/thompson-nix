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
    plugins.lualine = {
      enable = true;
      settings = {
        options = {
          theme = "dracula";
          iconsEnabled = true;
          globalstatus = true;
          sectionSeparators = {
            left = "";
            right = "";
          };
          componentSeparators = {
            left = "|";
            right = "|";
          };
        };
        sections = {
          lualine_a = [
            "buffers"
          ];
          lualine_b = [
            "branch"
          ];
          lualine_c = [
            "filetype"
          ];
          lualine_x = [
            "selectioncount"
          ];
          lualine_y = [
            "location"
          ];
          lualine_z = [
            "mode"
          ];
        };
      };
    };
    opts = {
      showmode = false;
    };
  };
}
