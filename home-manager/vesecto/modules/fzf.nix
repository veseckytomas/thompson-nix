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
  fzf_command = "fd --type f --strip-cwd-prefix --hidden --follow --exclude .git";
in {
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "${fzf_command}";
    fileWidgetCommand = "${fzf_command}";
    defaultOptions = [
      "-i"
      "--multi"
    ];
  };
  catppuccin.fzf = {
    enable = false;
    flavor = "mocha";
  };
}
