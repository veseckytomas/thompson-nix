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
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvimtools/none-ls-extras.nvim",
    "gbprod/none-ls-shellcheck.nvim",
  },
  event = "VeryLazy",
  config = function()
    local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
    local null_ls = require("null-ls")
    null_ls.setup({
      sources = {
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.diagnostics.selene,
        null_ls.builtins.formatting.clang_format,
        null_ls.builtins.diagnostics.trivy,
        null_ls.builtins.diagnostics.cppcheck,
        null_ls.builtins.formatting.black,
        null_ls.builtins.formatting.isort,
        null_ls.builtins.diagnostics.pylint,
        null_ls.builtins.formatting.shfmt,
        null_ls.builtins.formatting.phpcbf,
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.diagnostics.mypy,
        -- require("none-ls.diagnostics.ruff"),
        -- require("none-ls.formatting.ruff"),
        require("none-ls.formatting.latexindent"),
      },
      require("null-ls").register(require("none-ls-shellcheck.diagnostics")),
      require("null-ls").register(require("none-ls-shellcheck.code_actions")),
      on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({ async = false })
            end,
          })
        end
      end,
    })
    vim.keymap.set("n", "<C-I>", vim.lsp.buf.format, { desc = "Format buffer" })
  end,
}
