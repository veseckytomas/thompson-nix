#!/usr/bin/env bash
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
set -uo pipefail
# Runs as ExecStopPost, so a failing rm must never fail the unit.
set +o errexit

# Belt to keyboxd.service's SIGTERM: a SIGKILLed keyboxd cannot run its atexit handler, so it
# leaves the lock behind. Runs as ExecStopPost, so it must never fail the unit.

# shellcheck source=/dev/null
. "${KEYBOX_LOCK_LIB:-@keyboxLockLib@}"

dir="$(keybox_dir)"
[ -d "$dir" ] || exit 0

removed=0

lock="$dir/pubring.db.lock"
if [ -e "$lock" ] && keybox_lock_is_stale "$lock"; then
  rm -f -- "$lock" && removed=$((removed + 1))
fi

# Orphan stamps are residue from GnuPG's own stale-lock recovery; harmless but unbounded.
for stamp in "$dir"/.\#lk*; do
  [ -e "$stamp" ] || continue
  if [ "$(stat -c %h -- "$stamp" 2>/dev/null || echo 1)" -eq 1 ]; then
    rm -f -- "$stamp" && removed=$((removed + 1))
  elif keybox_lock_is_stale "$stamp"; then
    rm -f -- "$stamp" && removed=$((removed + 1))
  fi
done

printf 'keybox-sweep: removed %d stale lock file(s) from %s\n' "$removed" "$dir"
exit 0
