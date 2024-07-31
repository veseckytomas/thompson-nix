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
  "christoomey/vim-tmux-navigator",
  lazy = false,
  config = function()
    vim.keymap.set("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", { desc = "Window left" })
    vim.keymap.set("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", { desc = "Window down" })
    vim.keymap.set("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", { desc = "Window up" })
    vim.keymap.set("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", { desc = "Window right" })
  end,
}
