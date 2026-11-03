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
#
# Self-heal the Antigravity connection key: the dashboard persists it under the
# model-prefix alias 'agy', but the resolver only reads the canonical 'antigravity'.
set -euo pipefail

db="${OMNIROUTE_DB:?OMNIROUTE_DB not set}"

if [ ! -f "$db" ]; then
  echo "omniroute-normalize: no database at $db (provider not connected yet)"
  exit 0
fi

# Every call needs the busy timeout: the gateway's PRAGMA journal_mode=WAL on each open briefly locks exclusively.
sq() {
  sqlite3 -cmd ".timeout 30000" "$db" "$@"
}

# Exit 75 (EX_TEMPFAIL) so Restart=on-failure retries instead of reporting success without normalizing.
if [ "$(sq "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='provider_connections';")" != "1" ]; then
  echo "omniroute-normalize: provider_connections table absent (gateway not migrated yet)" >&2
  exit 75
fi

count="$(sq "SELECT count(*) FROM provider_connections WHERE provider='agy';")"

if [ "${count:-0}" -eq 0 ]; then
  echo "omniroute-normalize: no-op (no agy rows)"
  exit 0
fi

# provider is non-unique (round-robin accounts) so a plain rename is collision-safe.
sq "UPDATE provider_connections SET provider='antigravity' WHERE provider='agy';" >/dev/null

echo "omniroute-normalize: normalized $count agy->antigravity row(s)"
