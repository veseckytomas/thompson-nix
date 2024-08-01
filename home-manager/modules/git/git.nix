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

{ config, pkgs, ... }:

{
  # programs.git = {
  #   enable = true;
  #   userEmail = "vesecky@proton.me";
  #   userName = "Tomáš Vesecký";
  #   aliases = {
  #     st = "status";
  #     ci = "commit";
  #     co = "checkout";
  #     swn = "switch -c";
  #     brd = "branch -D";
  #     br = "branch";
  #     ll = "log --oneline --graph --all --decorate";
  #     f = "fetch -ap";
  #   };
  #   extraConfig = {
  #     core = {
  #       editor = "nvim";
  #     };
  #     push = {
  #       autoSetupRemote = true;
  #     };
  #     pull = {
  #       rebase = true;
  #     };
  #     rerere = {
  #       enable = true;
  #     };
  #     init = {
  #       defaultBranch = "master";
  #     };
  #   };
  # };
  home.file.".gitconfig".source = ./gitconfig;
}
