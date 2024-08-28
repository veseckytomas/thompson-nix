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
      providerSelector = ''
        function()
          return { "lsp", "indent" }
        end
      '';
    };
    opts = {
      foldcolumn = "0";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
    };
    extraConfigLua = ''
      vim.keymap.set("n", "<leader>zo", require("ufo").openAllFolds, { desc = "[O]pen all folds" })
      vim.keymap.set("n", "<leader>zc", require("ufo").closeAllFolds, { desc = "[C]lose all folds" })
      vim.keymap.set("n", "zp", function()
        local winid = ufo.peekFoldedLinesUnderCursor()
        if not winid then
          vim.lsp.buf.hover()
        end
      end, { desc = "[P]eek folded under cursor" })
    '';
  };
}
