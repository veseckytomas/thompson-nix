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
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  config = function()
    require("mason-tool-installer").setup({
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "clang-format",
        "clangd",
        "trivy",
        "black",
        "isort",
        "pylint",
        "bash-language-server",
        "selene",
        "shfmt",
        "bashls",
        "texlab",
        "phpcbf",
        "intelephense",
        "latexindent",
        "mutt-language-server",
        "bash-debug-adapter",
        "rust-analyzer",
        "codelldb",
        "typescript-language-server",
        "tailwindcss-language-server",
        "eslint-lsp",
        "prettierd",
        "js-debug-adapter",
        "mypy",
        "debugpy",
        "ruff-lsp",
        "rnix-lsp"
      },
      auto_update = true,
      run_on_start = true,
      start_delay = 2000,
      debounce_hours = 5,
    })
    vim.api.nvim_command("MasonToolsInstall")
    vim.api.nvim_command("MasonToolsUpdate")
    vim.api.nvim_command("MasonToolsClean")
  end,
}
