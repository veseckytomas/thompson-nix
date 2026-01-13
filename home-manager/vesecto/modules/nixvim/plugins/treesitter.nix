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
  programs.nixvim.plugins.treesitter = {
    enable = true;
    folding = true;
    #    folding.enable = true;
    #    indent.enable = true;
    #    highlight.enable = true;
    nixGrammars = true;
    nixvimInjections = true;
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      html
      bash
      ini
      javascript
      json
      cpp
      c
      java
      json5
      latex
      lua
      make
      markdown
      markdown-inline
      python
      regex
      rust
      scss
      sql
      tmux
      toml
      tsx
      tsv
      typescript
      vim
      vimdoc
      xml
      yaml
      nginx
      nix
    ];
    settings.incremental_selection.enable = true;
  };
}
