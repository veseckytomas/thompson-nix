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
#
# VLC resume-playback: stop anytime (even Ctrl+Q) and continue next time.
#
# Approach: force VLC's "Continue playback" via CLI flags. Editing
# ~/.config/vlc/vlcrc does NOT work — VLC rewrites that file on exit and reverts
# any non-default value (qt-continue) back to its commented default, so the
# setting never survives a session. CLI options override the config file and
# cannot be clobbered (verified: --qt-continue=2 auto-resumes even with no vlcrc
# present at all).
#
# Two launch paths are covered so resume applies however VLC starts:
#   1. Desktop entry (file manager, rofi -show drun, app menu): patch the vlc
#      package's .desktop and shadow it in ~/.local/share/applications (the XDG
#      user dir wins over the system entry).
#   2. Command name (rofi run-mode, terminal): wrap the `vlc` binary in
#      ~/.nix-profile/bin, which precedes the system path.
# Both inject:
#   --qt-continue=2   ->  "Always" continue playback (auto-resume, no prompt)
#   --qt-recentplay   ->  keep the recently-played list (where positions live)
#   --recursive=expand -> when a folder is opened, fully expand every
#                         subdirectory into the playlist instead of leaving
#                         season folders collapsed. Without this, opening a
#                         whole series only lists the season folders (collapsed
#                         until clicked), so the last-watched episode is not in
#                         the playlist and cannot be resumed to.
#
# Series workflow: opening a whole folder starts the playlist at the first file
# (native resume is per-file; VLC 3.0.x has no "restore last session"). The
# resumejump Lua interface script watches the playlist and, when a folder is
# loaded, jumps to the last-watched episode that is present in it: the globally
# last-watched episode if it is in the playlist (so opening the whole series
# resumes wherever you left off, e.g. S10E05), otherwise that directory's own
# last episode. Combined with --qt-continue=2, that episode also resumes at the
# saved time. With no record yet, the folder simply starts at episode 1.
#
# The script is placed in ~/.local/share/vlc/lua/intf/ and loaded via
# --extraintf luaintf --lua-intf resumejump on every launch. It keeps its state
# in $XDG_STATE_HOME/vlc/resumejump-state.txt (falling back to
# ~/.local/state/vlc), created on first run.
{
  pkgs,
  lib,
  ...
}: let
  vlcLaunchFlags = "--qt-continue=2 --qt-recentplay --recursive=expand --extraintf luaintf --lua-intf resumejump";

  # Desktop entry with the flags injected into its Exec line (used by the file
  # manager, rofi drun, app menu). Drop VLC's default `--started-from-file`:
  # with no file passed, that flag tells VLC to read the playlist from stdin,
  # and launchers like rofi close/redirect stdin, so VLC reads EOF and exits
  # immediately.
  vlcResumeDesktop = pkgs.runCommand "vlc-resume-desktop" {} ''
    mkdir -p $out/share/applications
    sed -E 's@^Exec=.*/bin/vlc.*$@Exec=${pkgs.vlc}/bin/vlc ${vlcLaunchFlags} %U@' \
      ${pkgs.vlc}/share/applications/vlc.desktop \
      > $out/share/applications/vlc.desktop
  '';

  # `vlc` command wrapper for launches that bypass the desktop entry (rofi
  # run-mode, terminal). ~/.nix-profile/bin precedes the system path.
  vlcWrapper = pkgs.writeShellScriptBin "vlc" ''
    exec ${pkgs.vlc}/bin/vlc ${vlcLaunchFlags} "$@"
  '';
in {
  home.packages = [vlcWrapper];

  xdg.dataFile."applications/vlc.desktop".source =
    "${vlcResumeDesktop}/share/applications/vlc.desktop";

  xdg.dataFile."vlc/lua/intf/resumejump.lua".source = ./resumejump.lua;

  # Refresh the desktop database so file managers / launchers pick up the
  # shadowed entry instead of a cached pointer to the system one.
  home.activation.vlcDesktopDb = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD ${pkgs.desktop-file-utils}/bin/update-desktop-database -q \
      "$HOME/.local/share/applications" || true
  '';
}
