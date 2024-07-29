--   ________
--  /_  __/ /_  ____  ____ ___  ____  _________  ____
--   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
--  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
-- /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
--                          /_/
-- Tomáš Vesecký
-- Email: vesecky@proton.me
-- GitHub: veseckytomas
-- GitLab: vesecky.tomas

return {
  "kevinhwang91/nvim-ufo",
  dependencies = "kevinhwang91/promise-async",
  lazy = false,
  config = function()
    local ufo = require("ufo")
    ufo.setup({
      provider_selector = function()
        return { "lsp", "indent" }
      end,
    })
    vim.o.foldcolumn = "0"
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    vim.keymap.set("n", "zo", ufo.openAllFolds, { desc = "Open all folds" })
    vim.keymap.set("n", "zc", ufo.closeAllFolds, { desc = "Close all folds" })
    vim.keymap.set("n", "zk", function()
      local winid = ufo.peekFoldedLinesUnderCursor()
      if not winid then
        vim.lsp.buf.hover()
      end
    end, { desc = "Peek folded under cursor" })
  end,
}
