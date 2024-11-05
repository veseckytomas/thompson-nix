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
{...}: {
  programs.git = {
    enable = true;
    userEmail = "vesecky@proton.me";
    userName = "Tomáš Vesecký";
    delta.catppuccin = {
      enable = true;
      flavor = "mocha";
    };
    aliases = {
      st = "status";
      ci = "commit";
      co = "switch";
      swn = "switch -c";
      brd = "branch -D";
      br = "branch";
      ll = "log --oneline --graph --all --decorate";
      f = "fetch -ap";
      ra = "remote add origin";
      cp = "cherry-pick";
      c = "clean -Xdf";
    };
    extraConfig = {
      core = {
        editor = "nvim";
      };
      push = {
        autoSetupRemote = true;
      };
      rerere = {
        enable = true;
      };
      init = {
        defaultBranch = "master";
      };
    };
  };
}
