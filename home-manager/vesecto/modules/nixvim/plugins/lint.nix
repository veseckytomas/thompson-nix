# ________
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
  pkgs,
  pkgs-stable,
  ...
}: {
  programs.nixvim = {
    plugins.lint = {
      enable = true;
      lintersByFt = {
        # CSS
        css = ["stylelint"];
        # HTML
        html = ["htmlhint"];
        # JavaScript
        javascript = ["eslint"];
        javascriptreact = ["eslint"];
        # LaTeX
        tex = ["chktex"];
        # Markdown
        markdown = ["markdownlint"];
        # Nix
        nix = ["statix"];
        # Python
        python = ["pylint"];
        # Rust
        rust = ["clippy"];
        # Shell
        bash = ["shellcheck"];
        # SQL
        sql = ["sqlfluff"];
        # Text
        text = ["vale"];
        # TypeScript
        typescript = ["eslint"];
        typescriptreact = ["eslint"];
        # C++
        cpp = ["cpplint"];
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
    eslint
    markdownlint-cli
    statix
    # pylint via programs.pylint module (python3Packages attr); bare top-level alias collides in buildEnv
    ruff
    clippy
    shellcheck
    # unstable sqlfluff pulls diff-cover whose self-tests fail on pygments drift; pin stable
    pkgs-stable.sqlfluff
    vale
    # cpplint 2.0.2 self-tests fail on current python (codecs.open deprecation warning leaks to stderr); skip them
    (cpplint.overridePythonAttrs (_: {doCheck = false;}))
  ];
}
