#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  pkgs,
  lib,
  ...
}: let
  # Only needs to match the running qtile's version: cmd-obj finds the session by socket path, not store path.
  qtile = "${pkgs.python3Packages.qtile}/bin/qtile";
  # The office hub sometimes exports DP-1-2 with a 0-byte EDID, leaving only VESA fallback modes.
  # The DELL U2412M dot clock, which identifies its 59.95Hz mode apart from eDP-1's 59.88Hz one.
  officeClock = "154\\.000MHz";
in {
  programs.autorandr = {
    enable = true;
    hooks.predetect = {
      "10_dp-1-2-modefix" = ''
        PATH=${lib.makeBinPath [pkgs.xrandr pkgs.gnugrep pkgs.gnused pkgs.coreutils]}:$PATH
        export DISPLAY=''${DISPLAY:-:0}
        export XAUTHORITY=''${XAUTHORITY:-$HOME/.Xauthority}
        xrandr --query 2>/dev/null | grep -q '^DP-1-2 connected' || exit 0
        # `autorandr --save ntb_office` rewrites the real EDID back, so re-assert the wildcard here.
        setup="$HOME/.config/autorandr/ntb_office/setup"
        [ -f "$setup" ] && ! grep -qx 'DP-1-2 \*' "$setup" \
          && sed -i 's|^DP-1-2 .*$|DP-1-2 *|' "$setup"
        # A lost EDID leaves DP-1-2 borrowing eDP-1's 193.25MHz mode, which is 59.88Hz and so
        # never matches the profile's 59.95; match on the DELL dot clock, not the resolution.
        xrandr --verbose --query 2>/dev/null | sed -n '/^DP-1-2 /,/^[^ \t]/p' \
          | grep -q '${officeClock}' && exit 0
        # Two modes are named 1920x1200, so address the DELL one by XID or --addmode picks eDP-1's.
        xid=$(xrandr --verbose --query 2>/dev/null \
          | grep -oE "1920x1200 \(0x[0-9a-f]+\) ${officeClock}" \
          | head -1 | sed -n 's/.*(\(0x[0-9a-f]*\)).*/\1/p')
        [ -n "$xid" ] && xrandr --addmode DP-1-2 "$xid" 2>/dev/null || true
      '';
    };
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

  # A missing EDID fingerprints as a sentinel that hard-mismatches, so wildcard that one output.
  # Patched in place rather than declared as a profile: a store symlink would break `autorandr --save`.
  home.activation.autorandrOfficeWildcard = lib.hm.dag.entryAfter ["linkGeneration"] ''
    setup="$HOME/.config/autorandr/ntb_office/setup"
    if [ -f "$setup" ] && ! ${pkgs.gnugrep}/bin/grep -qx 'DP-1-2 \*' "$setup"; then
      run ${pkgs.gnused}/bin/sed -i 's|^DP-1-2 .*$|DP-1-2 *|' "$setup"
      ${pkgs.gnugrep}/bin/grep -qx 'DP-1-2 \*' "$setup" \
        || echo "autorandr: DP-1-2 wildcard not applied to $setup" >&2
    fi
  '';
}
