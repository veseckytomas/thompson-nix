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
{
  inputs,
  pkgs,
  ...
}: {
  programs.yazi = {
    enable = true;
    # package = pkgs.yazi;
    package = inputs.yazi.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
      _7zz = pkgs._7zz-rar;
    };
    enableZshIntegration = true;
    shellWrapperName = "y";
    settings = {
      mgr = {
        ratio = [1 4 2];
        sort_by = "natural";
        sort_dir_first = true;
        sort_translit = true;
        show_symlink = true;
        show_hidden = true;
      };
      opener = {
        edit = [
          {
            run = "$EDITOR \"$@\"";
            desc = "Edit";
            block = true;
            for = "unix";
          }
        ];
        open = [
          {
            run = "xdg-open \"$@\"";
            desc = "Open";
            for = "unix";
          }
        ];
      };
      open = {
        rules = [
          { mime = "text/*"; use = [ "edit" "open" ]; }
          { mime = "application/json"; use = [ "edit" "open" ]; }
          { mime = "application/javascript"; use = [ "edit" "open" ]; }
          { mime = "application/xml"; use = [ "edit" "open" ]; }
          { name = "*.toml"; use = [ "edit" "open" ]; }
          { name = "*.nix"; use = [ "edit" "open" ]; }
          { name = "*.lua"; use = [ "edit" "open" ]; }
          { name = "*.py"; use = [ "edit" "open" ]; }
          { name = "*.rs"; use = [ "edit" "open" ]; }
          { name = "*.go"; use = [ "edit" "open" ]; }
          { name = "*.c"; use = [ "edit" "open" ]; }
          { name = "*.h"; use = [ "edit" "open" ]; }
          { name = "*.cpp"; use = [ "edit" "open" ]; }
          { name = "*.hpp"; use = [ "edit" "open" ]; }
          { name = "*.sh"; use = [ "edit" "open" ]; }
          { name = "*.bash"; use = [ "edit" "open" ]; }
          { name = "*.zsh"; use = [ "edit" "open" ]; }
          { name = "*.js"; use = [ "edit" "open" ]; }
          { name = "*.ts"; use = [ "edit" "open" ]; }
          { name = "*.jsx"; use = [ "edit" "open" ]; }
          { name = "*.tsx"; use = [ "edit" "open" ]; }
          { name = "*.html"; use = [ "edit" "open" ]; }
          { name = "*.css"; use = [ "edit" "open" ]; }
          { name = "*.scss"; use = [ "edit" "open" ]; }
          { name = "*.xml"; use = [ "edit" "open" ]; }
          { name = "*.yaml"; use = [ "edit" "open" ]; }
          { name = "*.yml"; use = [ "edit" "open" ]; }
          { name = "*.ini"; use = [ "edit" "open" ]; }
          { name = "*.conf"; use = [ "edit" "open" ]; }
          { name = "*.md"; use = [ "edit" "open" ]; }
          { name = "*.txt"; use = [ "edit" "open" ]; }
          { mime = "inode/directory"; use = [ "open" ]; }
          { name = "*"; use = [ "open" ]; }
        ];
      };
    };
  };
  catppuccin.yazi = {
    enable = true;
    flavor = "mocha";
  };
  home.packages = with pkgs; [
    ffmpeg-full
    _7zz
    jq
    poppler
    fd
    ripgrep
    fzf
    zoxide
    resvg
    imagemagick
    xclip
  ];
}
