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
{...}: let
  config_dir = ".config/git";
in {
  programs.git = {
    enable = true;
    userEmail = "vesecky@proton.me";
    userName = "Tomáš Vesecký";
    signing = {
      signByDefault = true;
      key = "86020E9B84233A43E5249EC4E397E45D1BC4E984";
    };
    aliases = {
      a = "add";
      ap = "add --patch";
      st = "status --short";
      ci = "commit";
      co = "switch";
      swn = "switch -c";
      brd = "branch -D";
      br = "branch";
      ll = "log --graph --all --decorate --pretty=format:'%C(magenta)%h %C(white) %an  %ar%C(auto)  %D%n%s%n'";
      f = "fetch -ap";
      ra = "remote add origin";
      ca = "!git add --all && git commit";
      cp = "cherry-pick";
      c = "clean -Xdf";
      r = "restore --staged :/";
      re = "restore :/";
      df = "diff --output-indicator-new=' ' --output-indicator-old=' '";
    };
    extraConfig = {
      core = {
        editor = "nvim";
        whitespace = "error";
        preloadIndex = true;
      };
      branch = {
        sort = "-committerdate";
      };
      tag = {
        sort = "-taggerdate";
      };
      commit = {
        verbose = true;
        template = "$HOME/${config_dir}/template";
      };
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
      "color \"decorate\"" = {
        HEAD = "red";
        branch = "blue";
        tag = "yellow";
        remoteBranch = "magenta";
      };
      "color \"branch\"" = {
        current = "magenta";
        local = "default";
        remote = "yellow";
        upstream = "green";
        plain = "blue";
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
      diff-so-fancy = {
        markEmptyLines = false;
      };
      "color \"diff\"" = {
        meta = "black bold";
        frag = "magenta";
        context = "white";
        whitespace = "yellow reverse";
        old = "red";
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
      rerere = {
        enable = true;
      };
      init = {
        defaultBranch = "master";
      };
      advice = {
        addEmptyPathspec = "false";
        pushNonFastForward = "false";
        statusHints = "false";
      };
      "url \"git@github.com:\"" = {
        insteadOf = "gh:";
      };
      "url \"git@gitlab.com:\"" = {
        insteadOf = "gl:";
      };
      "url \"git@gitlab.com:vesecky.tomas/\"" = {
        insteadOf = "glp:";
      };
      "url \"git@gitlab.fit.cvut.cz:\"" = {
        insteadOf = "fit:";
      };
      "url \"git@gitlab.fit.cvut.cz:vesecto1/\"" = {
        insteadOf = "fitp:";
      };
    };
  };
  catppuccin.delta = {
    enable = true;
    flavor = "mocha";
  };
  home.file = {
    "Git/migrate.sh".source = ./migrate.sh;
    "${config_dir}/template".source = ./template;
  };
}
