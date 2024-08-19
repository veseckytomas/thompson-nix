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
  programs.nixvim.plugins.conform-nvim = {
    enable = true;
    formatOnSave = {
      lspFallback = true;
      timeoutMs = 500;
    };
    formattersByFt = {
      # HTML
      html = [ "" ];
      # JavaScript
      javascript = [ "" ];
      javascriptreact = [ "" ];
      # JSON
      json = [ "" ];
      # Markdown
      markdown = [ "" ];
      # Python
      python = [ "" ];
      # Rust
      rust = [ "" ];
      # Shell
      sh = [ "" ];
      # SQL
      sql = [ "" ];
      # Text
      text = [ "" ];
      # TypeScript
      typescript = [ "" ];
      typescriptreact = [ "" ];
    };
  };
}

