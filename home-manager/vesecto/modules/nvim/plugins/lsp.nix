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
{...}: {
  programs.nixvim.plugins.lsp = {
    enable = true;

    keymaps = {
      silent = true;
      diagnostic = {
        "<leader>j" = "goto_next";
        "<leader>k" = "goto_prev";
      };
      lspBuf = {
        "<leader>K" = "hover";
        "<leader>cr" = "references";
        "<leader>cd" = "definition";
        "<leader>ci" = "implementation";
        "<leader>ct" = "type_definition";
      };
    };
    servers = {
      # Bash
      bashls.enable = true;

      # Docker
      docker-compose-language-service.enable = true;
      dockerls.enable = true;

      # Webdev
      eslint.enable = true;
      html.enable = true;
      jsonls.enable = true;
      nginx-language-server.enable = true;
      tsserver.enable = true;
      cssls.enable = true;
      tailwindcss.enable = true;

      # Lua
      lua-ls.enable = true;

      # Python
      pylsp.enable = true;
      pylyzer.enable = true;
      pyright.enable = true;
      ruff.enable = true;
      ruff-lsp.enable = true;

      # Rust
      # rust-analyzer = {
      #   enable = true;
      #   installCargo = true;
      #   installRustc = true;
      # };

      # SQL
      sqls.enable = true;

      # Latex
      texlab.enable = true;

      # Nix
      nil-ls.enable = true;

      # Markdown
      marksman.enable = true;

      # YAML
      yamlls.enable = true;
    };
  };
}
