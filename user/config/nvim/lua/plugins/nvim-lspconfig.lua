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
  "neovim/nvim-lspconfig",
  dependencies = {
    { "williamboman/mason.nvim", config = true },
    { "folke/neodev.nvim",       opts = {} },
    { "j-hui/fidget.nvim",       opts = {} },
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    require("mason-lspconfig").setup({})

    local lspconfig = require("lspconfig")
    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    local util = require("lspconfig.util")
    local servers = {
      "ruff_lsp",
      "lua_ls",
      "clangd",
      "mutt_ls",
      "bashls",
      "texlab",
      "intelephense",
      "tsserver",
      "tailwindcss",
      "eslint",
      "rnix"
    }
    for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup({ capabilities = capabilities })
    end

    -- Rust
    -- lspconfig.rust_analyzer.setup({
    --   capabilities = capabilities,
    --   filetypes = { "rust" },
    --   root_dir = util.root_pattern("Cargo.toml"),
    --   settings = {
    --     ["rust-analyzer"] = {
    --       cargo = {
    --         allFeatures = true,
    --       },
    --     },
    --   },
    -- })

    vim.keymap.set("n", "<leader>cd", require("telescope.builtin").lsp_definitions, { desc = "[C]ode [D]efinition" })
    vim.keymap.set("n", "<leader>cr", require("telescope.builtin").lsp_references, { desc = "[C]ode [R]eferences" })
    vim.keymap.set(
      "n",
      "<leader>ci",
      require("telescope.builtin").lsp_implementations,
      { desc = "[C]ode [I]mplementations" }
    )
    -- Jump to the type of the word under your cursor.
    --  Useful when you're not sure what type a variable is and you want to see
    --  the definition of its *type*, not where it was *defined*.
    vim.keymap.set(
      "n",
      "<leader>td",
      require("telescope.builtin").lsp_type_definitions,
      { desc = "[T]ype [D]efinition" }
    )
    -- Fuzzy find all the symbols in your current document.
    --  Symbols are things like variables, functions, types, etc.
    vim.keymap.set(
      "n",
      "<leader>ds",
      require("telescope.builtin").lsp_document_symbols,
      { desc = "[D]ocument [S]ymbols" }
    )
    -- Fuzzy find all the symbols in your current workspace.
    --  Similar to document symbols, except searches over your entire project.
    vim.keymap.set(
      "n",
      "<leader>ws",
      require("telescope.builtin").lsp_dynamic_workspace_symbols,
      { desc = "[W]orkspace [S]ymbols" }
    )
    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "[R]e[N]ame" })
    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ctions" })
    -- Opens a popup that displays documentation about the word under your cursor
    --  See `:help K` for why this keymap.
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    vim.keymap.set("n", "<leader>cD", vim.lsp.buf.declaration, { desc = "[C]ode [D]eclaration" })
  end,
}
