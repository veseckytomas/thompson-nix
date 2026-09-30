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
set -euo pipefail

# Reproduces the recycled-PID keybox deadlock: a lock naming a live non-keyboxd PID.
# GnuPG only treats a lock as stale when the PID is dead AND the hostname matches, so a
# recycled PID makes it wait out the hard-coded 10s timeout and fail with "No secret key".

readonly EXPECTED_PLAINTEXT='HARNESS_OK=1'
decrypt_cmd='gpg-decrypt-hardened'

while [ $# -gt 0 ]; do
  case "$1" in
    --decrypt-cmd)
      decrypt_cmd="${2:?--decrypt-cmd needs a value}"
      shift 2
      ;;
    -h | --help)
      printf 'usage: keybox-lock-harness [--decrypt-cmd <cmd>]\n'
      exit 0
      ;;
    *)
      printf 'keybox-lock-harness: unknown argument: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

harness_home=''

# shellcheck disable=SC2329  # invoked indirectly via trap
cleanup() {
  [ -n "$harness_home" ] || return 0
  GNUPGHOME="$harness_home" gpgconf --kill keyboxd >/dev/null 2>&1 || true
  GNUPGHOME="$harness_home" gpgconf --kill gpg-agent >/dev/null 2>&1 || true
  pkill -TERM -f "keyboxd --homedir $harness_home" >/dev/null 2>&1 || true
  sleep 1
  pkill -KILL -f "keyboxd --homedir $harness_home" >/dev/null 2>&1 || true
  rm -rf -- "$harness_home"
}
trap cleanup EXIT INT TERM

# Never operate on a real keyring: this script plants locks and kills daemons.
real_home="${GNUPGHOME:-$HOME/.gnupg}"
if [ "$real_home" = "$HOME/.gnupg" ] && [ -n "${GNUPGHOME:-}" ]; then
  printf 'keybox-lock-harness: refusing to run against %s/.gnupg\n' "$HOME" >&2
  exit 2
fi

harness_home="$(mktemp -d -t keybox-harness.XXXXXX)"
chmod 700 "$harness_home"
if [ "$harness_home" = "$HOME/.gnupg" ]; then
  printf 'keybox-lock-harness: refusing to run against %s/.gnupg\n' "$HOME" >&2
  exit 2
fi
printf 'use-keyboxd\n' >"$harness_home/common.conf"

export GNUPGHOME="$harness_home"

if ! gpg --batch --quiet --passphrase '' \
  --quick-generate-key harness@invalid default default never >/dev/null 2>&1; then
  printf 'HARNESS INVALID: could not generate a throwaway key\n' >&2
  exit 2
fi

printf '%s' "$EXPECTED_PLAINTEXT" |
  gpg --batch --quiet --yes --trust-model always \
    --recipient harness@invalid --encrypt --output "$harness_home/token.gpg"

plant_stale_lock() {
  local dir="$harness_home/public-keys.d" stamp
  gpgconf --kill keyboxd >/dev/null 2>&1 || true
  pkill -TERM -f "keyboxd --homedir $harness_home" >/dev/null 2>&1 || true
  sleep 1
  mkdir -p "$dir"
  rm -f "$dir"/.\#lk* "$dir/pubring.db.lock"
  # PID 1 is always alive, root-owned and never keyboxd - the recycled-PID shape, race-free.
  stamp="$dir/.#lk0xfeedface.$(uname -n).1"
  printf '%10d\n%s\n' 1 "$(uname -n)" >"$stamp"
  ln "$stamp" "$dir/pubring.db.lock"
}

run_probe() {
  local out rc
  set +e
  out="$(timeout 40 "$@" "$harness_home/token.gpg" 2>/tmp/keybox-harness-err.$$)"
  rc=$?
  set -e
  printf '%s' "$out"
  return $rc
}

is_lock_blocked() {
  grep -qE 'waiting for lock|keydb_search failed' "/tmp/keybox-harness-err.$$" 2>/dev/null
}

# The control proves the harness can actually fail; a harness that cannot go RED proves nothing.
plant_stale_lock
control_out=''
control_rc=0
control_out="$(run_probe gpg --batch --decrypt -q)" || control_rc=$?
if [ "$control_rc" -eq 0 ] && [ "$control_out" = "$EXPECTED_PLAINTEXT" ] && ! is_lock_blocked; then
  printf 'HARNESS INVALID: control (plain gpg) did not reproduce the lock\n' >&2
  rm -f "/tmp/keybox-harness-err.$$"
  exit 2
fi

if [ "$decrypt_cmd" = "gpg" ]; then
  printf 'RED: blocked on keybox lock (plain gpg, rc=%s)\n' "$control_rc"
  head -2 "/tmp/keybox-harness-err.$$" 2>/dev/null || true
  rm -f "/tmp/keybox-harness-err.$$"
  exit 1
fi

plant_stale_lock
subject_out=''
subject_rc=0
# shellcheck disable=SC2086
subject_out="$(run_probe $decrypt_cmd)" || subject_rc=$?

if [ "$subject_rc" -ne 0 ]; then
  printf 'RED: %s failed under a stale keybox lock (rc=%s)\n' "$decrypt_cmd" "$subject_rc"
  head -3 "/tmp/keybox-harness-err.$$" 2>/dev/null || true
  rm -f "/tmp/keybox-harness-err.$$"
  exit 1
fi

if [ "$subject_out" != "$EXPECTED_PLAINTEXT" ]; then
  printf 'RED: %s returned wrong plaintext (got %q)\n' "$decrypt_cmd" "$subject_out"
  rm -f "/tmp/keybox-harness-err.$$"
  exit 1
fi

rm -f "/tmp/keybox-harness-err.$$"
printf 'GREEN: %s recovered from a stale keybox lock and decrypted correctly\n' "$decrypt_cmd"
exit 0
