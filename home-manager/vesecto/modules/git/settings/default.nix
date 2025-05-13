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
  programs.git.extraConfig = {
    core = {
      editor = "nvim";
      whitespace = "error";
      preloadIndex = true;
    };
    branch.sort = "-committerdate";
    tag.sort = "-taggerdate";
    commit.verbose = true;
    rerere.enable = true;
    init.defaultBranch = "master";
    diff-so-fancy.markEmptyLines = false;
    push = {
      autoSetupRemote = true;
      default = "current";
      followTags = true;
    };
    pull = {
      default = "current";
      rebase = true;
    };
    rebase = {
      autoStash = true;
      missingCommitsCheck = "warn";
    };
    log = {
      abbrevCommit = true;
      graphColors = "blue,yellow,cyan,magenta,green,red";
    };
    diff = {
      context = 3;
      renames = "copies";
      interHunkContext = 10;
    };
    pager = {
      diff = "diff-so-fancy | $PAGER";
      branch = false;
      tag = false;
    };
    interactive = {
      diffFilter = "diff-so-fancy --patch";
      singleKey = true;
    };
    stash = {
      branch = true;
      showStash = true;
      showUntrackedFiles = "all";
    };
    advice = {
      addEmptyPathspec = "false";
      pushNonFastForward = "false";
      statusHints = "false";
    };
  };
  imports = [
    ./colors.nix
    ./urls.nix
  ];
  home.packages = with pkgs; [
    diff-so-fancy
  ];
}
