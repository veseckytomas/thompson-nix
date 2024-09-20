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
{pkgs, ...}: {
  programs.nixvim = {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "kulala.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "mistweaverco";
          repo = "kulala.nvim";
          rev = "f373b48b62fe0da8a6bff1ed64452d27313d568b";
          sha256 = "sha256-hLfnn94MkIR7ZUCjNLtZkuBHOWPHyDvBR6XkalphvX8=";
        };
      })
    ];
    extraConfigLua = ''
      require('kulala').setup()
      vim.filetype.add({
        extension = {
          ['http'] = 'http',
        },
      })
    '';
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>kr";
        action = "<cmd>lua require('kulala').run()<CR>";
        options.desc = "[K]ulala [R]un";
      }
    ];
  };
}
