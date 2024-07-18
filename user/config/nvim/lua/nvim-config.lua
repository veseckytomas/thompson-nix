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

-- set underscore as not part of a word
vim.cmd("set iskeyword-=_")

-- set line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- set clipboard to system clipboard
vim.opt.clipboard = "unnamedplus"

-- set leader
vim.g.mapleader = " "

-- enable mouse support
vim.opt.mouse = "a"

-- enable break indent
vim.opt.breakindent = true

-- save undo history
vim.opt.undofile = true

-- case insensitive search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- set updatetime
vim.opt.updatetime = 500

-- set signcolumn
vim.opt.signcolumn = "yes"

-- set how non-text characters are displayed
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- preview substitutions live
vim.opt.inccommand = "split"

-- show which line your cursor is on
vim.opt.cursorline = true

-- minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- set better move between windows
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- set open split keymaps
vim.keymap.set("n", "<leader>vs", "<cmd>vsplit<CR>", { desc = "[V]ertical [S]plit" })
vim.keymap.set("n", "<leader>hs", "<cmd>split<CR>", { desc = "[H]orizontal [S]plit" })

-- set escape keymap
vim.keymap.set("i", "jj", "<Esc>", { desc = "Normal Mode" })

-- set terminal keymap
vim.keymap.set("n", "<leader>tt", "<cmd>terminal<CR>", { desc = "Open Terminal" })

-- set buffer keymaps
vim.keymap.set("n", "<leader>bd", "<cmd>bd<CR>", { desc = "Close Buffer" })
vim.keymap.set("n", "<leader>bn", "<cmd>bn<CR>", { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bp", "<cmd>bp<CR>", { desc = "Previous Buffer" })

-- disable perl provider
vim.cmd("let g:loaded_perl_provider = 0")
