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
    plugins.conform-nvim = {
      enable = true;
      settings = {
        format_on_save = {
          lspFallback = true;
          timeoutMs = 500;
        };
        formatters_by_ft = {
          # CSS
          css = ["prettierd" "prettier"];
          scss = ["prettierd" "prettier"];
          # HTML
          html = ["htmlbeautifier"];
          # JavaScript
          javascript = ["prettierd" "prettier"];
          javascriptreact = ["prettierd" "prettier"];
          # JSON
          json = ["jq"];
          # LaTeX
          tex = ["latexindent"];
          # Markdown
          markdown = ["prettierd" "prettier"];
          # Nix
          nix = ["alejandra"];
          # Python
          python = ["isort" "black"];
          # Rust
          rust = ["rustfmt"];
          # Shell
          bash = ["beautysh"];
          # SQL
          sql = ["pg_format"];
          # TOML
          toml = ["taplo"];
          # TypeScript
          typescript = ["prettierd" "prettier"];
          typescriptreact = ["prettierd" "prettier"];
          # YAML
          yaml = ["yamlfix"];
          # C++
          cpp = ["clang-format"];
          # Java
          java = ["google-java-format"];
          # Typst
          typ = ["prettypst"];
        };
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<C-I>";
        action.__raw = ''
          function()
            require("conform").format({
                 lsp_fallback = true,
                 async = false,
                 timeout_ms = 500,
          })
          end
        '';
        options.desc = "Format";
      }
    ];
  };
  home.packages = with pkgs; [
    prettypst
    # latexindent ships in lint.nix's scoped texlive; a second one here would collide on the texlive pname.
    codespell
    prettierd
    prettier
    rubyPackages.htmlbeautifier
    jq
    alejandra
    isort
    black
    rustfmt
    beautysh
    pgformatter
    taplo
    yamlfix
    clang-tools
    google-java-format
  ];
}
