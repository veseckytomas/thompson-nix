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
        markdown = ["markdownlint"];
        # Nix
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
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>lr";
        action.__raw = ''
          function()
            require("lint").try_lint()
          end
        '';
        options.desc = "[L]inter [R]un";
      }
    ];
  };
  home.packages = with pkgs; [
    htmlhint
    nodePackages.eslint
    nodePackages.jsonlint
    markdownlint-cli
    statix
    pylint
    ruff
    clippy
    shellcheck
    sqlfluff
    vale
  ];
}
