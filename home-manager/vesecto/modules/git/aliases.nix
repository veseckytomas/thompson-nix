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
  programs.git.aliases = {
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
}
