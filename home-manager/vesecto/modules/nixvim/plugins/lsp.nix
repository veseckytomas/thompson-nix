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
{pkgs, ...}: {
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
        "<leader>ca" = "code_action";
      };
    };
    servers = {
      # Bash
      bashls.enable = true;

      # Gitlab
      gitlab_ci_ls.enable = true;

      # Docker
      docker_compose_language_service.enable = true;
      dockerls.enable = true;

      # Webdev
      eslint.enable = true;
      html.enable = true;
      jsonls.enable = true;
      nginx_language_server.enable = true;
      ts_ls.enable = true;
      cssls.enable = true;

      # Lua
      lua_ls.enable = true;

      # Python
      pylsp.enable = true;

      # SQL
      sqls.enable = true;

      # Latex
      texlab.enable = true;

      # Nix
      nixd.enable = true;

      # Markdown
      marksman.enable = true;

      # YAML
      yamlls.enable = true;

      # C++
      clangd.enable = true;

      # Typst
      tinymist.enable = true;
    };
  };
  home.packages = with pkgs; [
    # LSP servers
    bash-language-server
    nixd
  ];
}
