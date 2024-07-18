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
  "vim-test/vim-test",
  dependencies = {
    "preservim/vimux",
  },
  config = function()
    vim.keymap.set("n", "<leader>t", "<cmd>TestNearest<CR>", {})
    vim.keymap.set("n", "<leader>T", "<cmd>TestFile<CR>", {})
    vim.keymap.set("n", "<leader>a", "<cmd>TestSuite<CR>", {})
    vim.keymap.set("n", "<leader>l", "<cmd>TestLast<CR>", {})
    vim.keymap.set("n", "<leader>g", "<cmd>TestVisit<CR>", {})
    vim.cmd("let test#strategy = 'vimux'")
  end,
}
