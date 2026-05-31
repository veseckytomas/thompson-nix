#!/usr/bin/env bash
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

### AUTOSTART PROGRAMS ###
export XDG_CURRENT_DESKTOP=qtile
export XDG_SESSION_DESKTOP=qtile
export DESKTOP_SESSION=qtile
export XDG_SESSION_TYPE=x11

dbus-update-activation-environment --systemd \
  XDG_CURRENT_DESKTOP \
  XDG_SESSION_DESKTOP \
  DESKTOP_SESSION \
  XDG_SESSION_TYPE \
  PATH

systemctl --user import-environment \
  XDG_CURRENT_DESKTOP \
  XDG_SESSION_DESKTOP \
  DESKTOP_SESSION \
  XDG_SESSION_TYPE \
  PATH

systemctl --user restart xdg-desktop-portal.service

nm-applet &
amixer set Master off
xbindkeys &

### Display Settings ###
xset s off
xset s noblank
xset -dpms
