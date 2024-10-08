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
    signing = {
      signByDefault = true;
      key = "86020E9B84233A43E5249EC4E397E45D1BC4E984";
    };
    aliases = {
      st = "status";
      ci = "commit";
      co = "checkout";
      swn = "switch -c";
      brd = "branch -D";
      br = "branch";
      ll = "log --oneline --graph --all --decorate";
      f = "fetch -ap";
      ra = "remote add origin";
      ca = "-i :/";
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
  home.file."Git/migrate.sh".source = ./migrate.sh;
}
