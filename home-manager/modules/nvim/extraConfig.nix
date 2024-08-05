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

{ config, pkgs, ... }:

{
  programs.nixvim.extraConfigLua = ''
    -- set underscore as not part of a word
    vim.cmd("set iskeyword-=_")

    -- disable perl provider
    vim.cmd("let g:loaded_perl_provider = 0")
  '';



  # programs.nixvim.extraConfigLua = ''
  #   -- set underscore as not part of a word
  #   vim.cmd("set iskeyword-=_")
  #
  #   -- set line numbers
  #   vim.opt.number = true
  #   vim.opt.relativenumber = true
  #
  #   -- set clipboard to system clipboard
  #   vim.opt.clipboard = "unnamedplus"
  #
  #   -- set leader
  #   vim.g.mapleader = " "
  #
  #   -- enable mouse support
  #   vim.opt.mouse = "a"
  #
  #   -- enable break indent
  #   vim.opt.breakindent = true
  #
  #   -- save undo history
  #   vim.opt.undofile = true
  #
  #   -- case insensitive search
  #   vim.opt.ignorecase = true
  #   vim.opt.smartcase = true
  #
  #   -- set updatetime
  #   vim.opt.updatetime = 500
  #
  #   -- set signcolumn
  #   vim.opt.signcolumn = "yes"
  #
  #   -- set how non-text characters are displayed
  #   vim.opt.list = true
  #   vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
  #
  #   -- preview substitutions live
  #   vim.opt.inccommand = "split"
  #
  #   -- show which line your cursor is on
  #   vim.opt.cursorline = true
  #
  #   -- minimal number of screen lines to keep above and below the cursor.
  #   vim.opt.scrolloff = 10
  #
  #   -- set highlight on search, but clear on pressing <Esc> in normal mode
  #   vim.opt.hlsearch = true
  #
  #   -- disable perl provider
  #   vim.cmd("let g:loaded_perl_provider = 0")
  # '';
}

