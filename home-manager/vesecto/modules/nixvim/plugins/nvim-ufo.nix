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
    plugins.nvim-ufo = {
      enable = true;
      settings.provider_selector = ''
        function()
          -- return { "lsp", "indent" }
          return { "indent" }
        end
      '';
    };
    opts = {
      foldcolumn = "0";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>zo";
        action.__raw = ''
          require("ufo").openAllFolds
        '';
        options.desc = "[O]pen all folds";
      }
      {
        mode = ["n"];
        key = "<leader>zc";
        action.__raw = ''
          require("ufo").closeAllFolds
        '';
        options.desc = "[C]lose all folds";
      }
      {
        mode = ["n"];
        key = "<leader>zp";
        action.__raw = ''
          function()
            local winid = ufo.peekFoldedLinesUnderCursor()
            if not winid then
              vim.lsp.buf.hover()
            end
          end
        '';
        options.desc = "[P]eek folded under cursor";
      }
    ];
  };
}
