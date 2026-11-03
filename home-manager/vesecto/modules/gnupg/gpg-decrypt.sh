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
# This script classifies and retries gpg failures itself, so errexit must stay off even when
# a wrapper (writeShellApplication) turns it on.
set +o errexit

# Decrypt through a keybox lock that GnuPG itself cannot clear: it only treats a lock as stale
# when the PID is dead, so a PID recycled to an unrelated process blocks every attempt until
# the 10s timeout, then reports the misleading "No secret key".

# shellcheck source=/dev/null
. "${KEYBOX_LOCK_LIB:-@keyboxLockLib@}"

readonly MAX_ATTEMPTS=4
pinentry='error'

while [ $# -gt 0 ]; do
  case "$1" in
    --pinentry)
      pinentry="${2:?--pinentry needs error|ask}"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      printf 'gpg-decrypt-hardened: unknown option: %s\n' "$1" >&2
      exit 2
      ;;
    *) break ;;
  esac
done

case "$pinentry" in
  error | ask) ;;
  *)
    printf 'gpg-decrypt-hardened: --pinentry must be error|ask, got %s\n' "$pinentry" >&2
    exit 2
    ;;
esac

blob="${1:-}"
if [ -z "$blob" ]; then
  printf 'gpg-decrypt-hardened: usage: gpg-decrypt-hardened [--pinentry error|ask] <file.gpg>\n' >&2
  exit 2
fi

lock="$(keybox_dir)/pubring.db.lock"
errfile="$(mktemp -t gpg-decrypt-err.XXXXXX)"
trap 'rm -f -- "$errfile"' EXIT INT TERM

killed_keyboxd=0
classification='none'
attempt=1

while [ "$attempt" -le "$MAX_ATTEMPTS" ]; do
  : >"$errfile"
  if out="$(gpg --batch --no-tty --pinentry-mode "$pinentry" --decrypt -q "$blob" 2>"$errfile")" \
    && [ -n "$out" ]; then
    printf '%s' "$out"
    exit 0
  fi

  if ! grep -qE 'waiting for lock|keydb_search failed' "$errfile"; then
    classification='not-a-lock-failure'
    break
  fi

  if keybox_lock_is_stale "$lock"; then
    classification='stale-lock'
    gpgconf --unlock pubring.db >/dev/null 2>&1
    keybox_clear_lock "$lock"
  else
    classification='held-by-live-keyboxd'
    # Our own keyboxd is wedged rather than stale; surgical restart, never --kill all,
    # which would also drop the login session's gpg-agent PIN cache.
    if [ "$attempt" -ge 3 ] && [ "$killed_keyboxd" -eq 0 ]; then
      gpgconf --kill keyboxd >/dev/null 2>&1 || true
      killed_keyboxd=1
    fi
  fi

  [ "$attempt" -lt "$MAX_ATTEMPTS" ] && sleep $((1 << (attempt - 1)))
  attempts_made="$attempt"
  attempt=$((attempt + 1))
done

printf 'gpg-decrypt-hardened: failed to decrypt %s after %d attempt(s) [%s]\n' \
  "$blob" "${attempts_made:-1}" "$classification" >&2
head -3 "$errfile" >&2 2>/dev/null
exit 1
