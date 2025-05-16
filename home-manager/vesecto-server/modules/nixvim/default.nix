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
    enable = true;

    # Set default editor
    defaultEditor = true;

    # Enable aliases
    vimdiffAlias = true;
    vimAlias = true;
    viAlias = true;

    # Set colorscheme
    colorschemes.catppuccin = {
      enable = true;
    };

    # Set clipboard
    clipboard = {
      register = "unnamedplus";
      providers.xclip.enable = true;
    };

    globals = {
      mapleader = " ";
      db_ui_use_nerd_fonts = 1;
    };

    opts = {
      # Disable swap files
      swapfile = true;

      # Set line numbers
      number = true;
      relativenumber = true;

      # Enable mouse support
      mouse = "a";

      # Enable break indent
      breakindent = true;

      # Save undo history
      undofile = true;

      # Case insensitive search
      ignorecase = true;
      smartcase = true;

      # Set updatetime
      updatetime = 500;

      # Set signcolumn
      signcolumn = "yes";

      # Set how non-text characters are displayed
      list = true;
      listchars = {
        tab = "» ";
        trail = "·";
        nbsp = "␣";
      };

      # Preview substitutions live
      inccommand = "split";

      # Show which line your cursor is on
      cursorline = true;

      # Minimal number of screen lines to keep above and below the cursor.
      scrolloff = 10;

      # Set highlight on search, but clear on pressing <Esc> in normal mode
      hlsearch = true;

      # Tab options
      tabstop = 2;
      shiftwidth = 2;
      softtabstop = 2;
      expandtab = true;
      autoindent = true;
    };
  };
  home.packages = with pkgs; [
    ripgrep
    xclip
  ];

  imports = [
    ./extraConfig.nix
    ./keymaps.nix
    ./performance.nix
    ./plugins
  ];
}
