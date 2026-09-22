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
  pkgs,
  pkgs-stable,
  ...
}: {
  programs.autorandr = {
    enable = true;
    hooks.postswitch = {
      "20_qtile-reload" = ''
        # Reload qtile to update screens and bars
        if ${pkgs.procps}/bin/pgrep -x qtile > /dev/null; then
           # Using DISPLAY and XAUTHORITY from our earlier symlink fix
           export DISPLAY=:0
           export XAUTHORITY=$HOME/.Xauthority
           ${pkgs-stable.python3.pkgs.qtile}/bin/qtile cmd-obj -o cmd -f reload_config
        fi
      '';
    };
  };
}
