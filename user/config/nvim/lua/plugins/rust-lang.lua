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
  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },
  -- {
  --   "simrat39/rust-tools.nvim",
  --   depencencies = {
  --     "neovim/nvim-lspconfig",
  --   },
  --   ft = "rust",
  --   opts = function()
  --     require("lspconfig")
  --     local capabilities = require("cmp_nvim_lsp").default_capabilities()
  --     local util = require("lspconfig.util")
  --     return {
  --       server = {
  --         capabilities = capabilities,
  --         filetypes = { "rust" },
  --         root_dir = util.root_pattern("Cargo.toml"),
  --         settings = {
  --           ["rust-analyzer"] = {
  --             cargo = {
  --               allFeatures = true,
  --             },
  --           },
  --         },
  --       },
  --     }
  --   end,
  --   config = function(_, opts)
  --     require("rust-tools").setup(opts)
  --   end,
  -- },
  {
    "mrcjkb/rustaceanvim",
    ft = "rust",
    lazy = false,
  },
  {
    "saecki/crates.nvim",
    ft = { "rust", "toml" },
    config = function(_, opts)
      local crates = require("crates")
      crates.setup(opts)
      crates.show()
      vim.keymap.set("n", "<leader>cu", crates.upgrade_all_crates, { desc = "[C]rates [U]pgrade" })
    end,
  },
}
