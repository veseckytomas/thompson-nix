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
{pkgs, ...}: let
  # Only needs to match the running qtile's version: cmd-obj finds the session by socket path, not store path.
  qtile = "${pkgs.python3Packages.qtile}/bin/qtile";
in {
  programs.autorandr = {
    enable = true;
    hooks.postswitch = {
      "20_qtile-reload" = ''
        # Using DISPLAY and XAUTHORITY from our earlier symlink fix
        export DISPLAY=:0
        export XAUTHORITY=$HOME/.Xauthority
        # Nix runs qtile as .qtile-wrapped, so `pgrep -x qtile` never matched; ask the running instance instead
        if ${qtile} cmd-obj -o cmd -f status > /dev/null 2>&1; then
           # The system autorandr unit has no session env, so point at the user bus ourselves
           export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
           export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
           # restart, not reload_config: reload leaves a queued bar draw holding finalized widgets, which crashes in Bar._resize
           qtile_restart="${qtile} cmd-obj -o cmd -f restart"
           # systemd-run refuses a live unit name, so drop the pending timer first to make autorandr's double-fire latest-wins
           # The service must go too: once the timer has fired it stays loaded and still blocks the name.
           ${pkgs.systemd}/bin/systemctl --user stop qtile-screen-restart.timer qtile-screen-restart.service 2>/dev/null
           ${pkgs.systemd}/bin/systemd-run --user --quiet --collect \
             --unit=qtile-screen-restart --on-active=3 \
             --setenv=DISPLAY=:0 --setenv=XAUTHORITY=$XAUTHORITY \
             $qtile_restart \
           || { ${pkgs.coreutils}/bin/sleep 3; $qtile_restart; }
        fi
      '';
    };
  };
}
