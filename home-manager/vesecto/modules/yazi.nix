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
