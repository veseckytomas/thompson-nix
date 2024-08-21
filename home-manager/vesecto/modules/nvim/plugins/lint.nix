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
{
  config,
  pkgs,
  ...
}: {
  programs.nixvim = {
    plugins.lint = {
      enable = true;
      lintersByFt = {
        # HTML
        html = ["htmlhint"];
        # JavaScript
        javascript = ["eslint"];
        javascriptreact = ["eslint"];
        # JSON
        json = ["jsonlint"];
        # Markdown
        markdown = ["markdownlint"]; # Nix
        nix = ["statix"];
        # Python
        python = ["pylint" "ruff"];
        # Rust
        rust = ["clipy"];
        # Shell
        bash = ["shellcheck"];
        # SQL
        sql = ["sqlfluff"];
        # Text
        text = ["vale"];
        # TypeScript
        typescript = ["eslint"];
        typescriptreact = ["eslint"];
      };
    };
    extraConfigLua = ''
      vim.keymap.set("n", "<leader>lr", function() require("lint").try_lint() end, { desc = "[L]inter [R]un" })
    '';
  };
}
