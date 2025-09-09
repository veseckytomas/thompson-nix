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
nm-applet &
amixer set Master off
xbindkeys &
systemctl --user import-environment PATH && systemctl --user restart xdg-desktop-portal.service
rclone mount eOnedrive: ~/mnt/Onedrive --vfs-cache-mode full --daemon &
maestral start &

### Display Settings ###
xset s off
xset s noblank
xset -dpms

### Mouse Settings ###
xinput --set-prop "Logitech MX Vertical Advanced Ergonomic Mouse" "libinput Accel Speed" -0.7
