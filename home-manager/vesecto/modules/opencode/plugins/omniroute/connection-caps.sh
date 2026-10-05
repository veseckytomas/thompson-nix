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
#
# Idempotently set max_concurrent=4 on e-infra litellm connections so executeTargetGates skips a full 4-slot pool.
set -euo pipefail

db="${OMNIROUTE_DB:?OMNIROUTE_DB not set}"

if [ ! -f "$db" ]; then
  echo "omniroute-caps: no database at $db (litellm not seeded yet)"
  exit 0
fi

# Every call needs the busy timeout because the gateway's WAL pragma briefly locks at startup.
sq() {
  sqlite3 -cmd ".timeout 30000" "$db" "$@"
}

# Exit 75 (EX_TEMPFAIL) so Restart=on-failure retries after gateway migration.
if [ "$(sq "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='provider_connections';")" != "1" ]; then
  echo "omniroute-caps: provider_connections table absent (gateway not migrated yet)" >&2
  exit 75
fi

# json_valid() must short-circuit malformed provider metadata before json_extract().
count="$(sq "SELECT count(*) FROM provider_connections WHERE json_valid(provider_specific_data) AND json_extract(provider_specific_data,'$.prefix')='litellm' AND (max_concurrent IS NULL OR max_concurrent != 4);")"

if [ "${count:-0}" -eq 0 ]; then
  echo "omniroute-caps: no-op (no litellm cap drift found)"
  exit 0
fi

# Nix owns this cap, so every valid litellm row is corrected on each run.
sq "UPDATE provider_connections SET max_concurrent=4 WHERE json_valid(provider_specific_data) AND json_extract(provider_specific_data,'$.prefix')='litellm';" >/dev/null

echo "omniroute-caps: set $count litellm cap row(s) to max_concurrent=4"
