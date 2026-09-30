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
# shellcheck shell=bash

# Shared keybox dotlock classification, sourced by gpg-decrypt and keybox-sweep.

keybox_dir() {
  printf '%s/public-keys.d' "${GNUPGHOME:-$HOME/.gnupg}"
}

# Lock stamps are "<pid>\n<hostname>"; the installed lock is a hardlink to one of them.
keybox_lock_pid() {
  local file="$1"
  [ -r "$file" ] || return 1
  sed -n '1s/[^0-9]//gp' "$file" | head -1
}

keybox_lock_host() {
  local file="$1"
  [ -r "$file" ] || return 1
  sed -n '2p' "$file"
}

# A lock is stale unless a LIVE keyboxd on THIS host owns it. Link count proves only that a
# lock is installed, never that its holder lives: the lock that broke boot was a links=2 pair
# whose PID had been recycled to an unrelated process.
keybox_lock_is_stale() {
  local file="$1" pid host comm
  [ -e "$file" ] || return 1

  pid="$(keybox_lock_pid "$file" 2>/dev/null || true)"
  [ -n "$pid" ] || return 0

  host="$(keybox_lock_host "$file" 2>/dev/null || true)"
  if [ -n "$host" ] && [ "$host" != "$(uname -n)" ]; then
    return 0
  fi

  kill -0 "$pid" 2>/dev/null || return 0

  comm="$(cat "/proc/$pid/comm" 2>/dev/null || true)"
  [ "$comm" = "keyboxd" ] || return 0

  return 1
}

# Remove an installed lock together with the stamp it is hardlinked to; leaving the stamp is
# what accumulates orphan residue. Stamps held by a live keyboxd are never touched.
keybox_clear_lock() {
  local lock="$1" dir inode stamp
  dir="$(dirname -- "$lock")"
  inode=''
  [ -e "$lock" ] && inode="$(stat -c %i -- "$lock" 2>/dev/null || true)"
  rm -f -- "$lock"

  for stamp in "$dir"/.\#lk*; do
    [ -e "$stamp" ] || continue
    if [ -n "$inode" ] && [ "$(stat -c %i -- "$stamp" 2>/dev/null || echo 0)" = "$inode" ]; then
      rm -f -- "$stamp"
    elif [ "$(stat -c %h -- "$stamp" 2>/dev/null || echo 1)" -eq 1 ]; then
      rm -f -- "$stamp"
    elif keybox_lock_is_stale "$stamp"; then
      rm -f -- "$stamp"
    fi
  done
}
