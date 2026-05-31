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
          }
        ];
        open = [
          {
            run = "xdg-open \"$@\"";
            desc = "Open";
          }
        ];
      };
      open = {
        rules = [
          {
            mime = "text/*";
            use = ["edit" "open"];
          }
          {
            mime = "application/json";
            use = ["edit" "open"];
          }
          {
            mime = "application/javascript";
            use = ["edit" "open"];
          }
          {
            mime = "application/xml";
            use = ["edit" "open"];
          }
          {
            url = "*.toml";
            use = ["edit" "open"];
          }
          {
            url = "*.nix";
            use = ["edit" "open"];
          }
          {
            url = "*.lua";
            use = ["edit" "open"];
          }
          {
            url = "*.py";
            use = ["edit" "open"];
          }
          {
            url = "*.rs";
            use = ["edit" "open"];
          }
          {
            url = "*.go";
            use = ["edit" "open"];
          }
          {
            url = "*.c";
            use = ["edit" "open"];
          }
          {
            url = "*.h";
            use = ["edit" "open"];
          }
          {
            url = "*.cpp";
            use = ["edit" "open"];
          }
          {
            url = "*.hpp";
            use = ["edit" "open"];
          }
          {
            url = "*.sh";
            use = ["edit" "open"];
          }
          {
            url = "*.bash";
            use = ["edit" "open"];
          }
          {
            url = "*.zsh";
            use = ["edit" "open"];
          }
          {
            url = "*.js";
            use = ["edit" "open"];
          }
          {
            url = "*.ts";
            use = ["edit" "open"];
          }
          {
            url = "*.jsx";
            use = ["edit" "open"];
          }
          {
            url = "*.tsx";
            use = ["edit" "open"];
          }
          {
            url = "*.html";
            use = ["edit" "open"];
          }
          {
            url = "*.css";
            use = ["edit" "open"];
          }
          {
            url = "*.scss";
            use = ["edit" "open"];
          }
          {
            url = "*.xml";
            use = ["edit" "open"];
          }
          {
            url = "*.yaml";
            use = ["edit" "open"];
          }
          {
            url = "*.yml";
            use = ["edit" "open"];
          }
          {
            url = "*.ini";
            use = ["edit" "open"];
          }
          {
            url = "*.conf";
            use = ["edit" "open"];
          }
          {
            url = "*.md";
            use = ["edit" "open"];
          }
          {
            url = "*.txt";
            use = ["edit" "open"];
          }
          {
            mime = "inode/directory";
            use = ["open"];
          }
          {
            url = "*";
            use = ["open"];
          }
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
