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

{ config, pkgs, ... }:

{
  programs.nixvim = {
    plugins.lint = {
      enable = true;
      lintersByFt = {
        # HTML
        html = [ "htmlhint" ];
        # JavaScript
        javascript = [ "eslint" ];
        javascriptreact = [ "eslint" ];
        # JSON
        json = [ "jsonlint" ];
        # Markdown
        markdown = [ "markdownlint" ];
        # Nix
        nix = [ "nix" ];
        # Python
        python = [ "pylint" "ruff" ];
        # Rust
        rust = [ "clipy" ];
        # Shell
        sh = [ "shellcheck" ];
        # SQL
        sql = [ "sqlfluff" ];
        # Text
        text = [ "vale" ];
        # TypeScript
        typescript = [ "eslint" ];
        typescriptreact = [ "eslint" ];
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>lr";
        action = "<CMD>lua function() lint.try_lint() end<CR>";
        options.desc = "[L]inter [R]un";
      }
    ];
  };
}

