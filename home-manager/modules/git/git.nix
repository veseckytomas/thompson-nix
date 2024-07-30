{ config, pkgs, ... }:

{
  programs.git = {
    userEmail = "vesecky@proton.me";
    userName = "Tomáš Vesecký";
    signing = {
      signByDefault = true;
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
    };
    core = {
      editor = "nvim";
    };
    push = {
      autoSetupRemote = true;
    };
    pull = {
      rebase = true;
    };
    rerere = {
      enable = true;
    };
    init = {
      defaultBranch = "master";
    };
  };
}
