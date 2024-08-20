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
    plugins.conform-nvim = {
      enable = true;
      formatOnSave = {
        lspFallback = true;
        timeoutMs = 500;
      };
      formattersByFt = {
        # All filetypes
        "*" = [ "codespell" ];
        # CSS
        css = [ "prettierd" "prettier" ];
        scss = [ "prettierd" "prettier" ];
        # HTML
        html = [ "htmlbeautifier" ];
        # JavaScript
        javascript = [ "prettierd" "prettier" ];
        javascriptreact = [ "prettierd" "prettier" ];
        # JSON
        json = [ "" ];
        # Markdown
        markdown = [ "prettierd" "prettier" ];
        # Nix
        nix = [ "alejandra" ];
        # Python
        python = [ "isort" "black" ];
        # Rust
        rust = [ "reustfmt" ];
        # Shell
        bash = [ "beautysh" ];
        # SQL
        sql = [ "pg_format" ];
        # TOML
        toml = [ "taplo" ];
        # TypeScript
        typescript = [ "prettierd" "prettier" ];
        typescriptreact = [ "prettierd" "prettier" ];
        # YAML
        yaml = [ "yamlfix" ];
        # Other
        "_" = [ "trim_whitespace" ];
      };
    };
    extraConfigLua = ''
      vim.keymap.set("n", "<C-I>", function() require("conform").format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 500,
      }) end, { desc = "[L]inter [R]un" })
    '';
  };
}

