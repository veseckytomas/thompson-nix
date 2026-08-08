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
# Self-heal the Antigravity connection key: the dashboard persists it under the
# model-prefix alias 'agy', but the resolver only reads the canonical 'antigravity'.
set -euo pipefail

db="${OMNIROUTE_DB:?OMNIROUTE_DB not set}"

if [ ! -f "$db" ]; then
  echo "omniroute-normalize: no database at $db (provider not connected yet)"
  exit 0
fi

if [ "$(sqlite3 "$db" 'PRAGMA quick_check;')" != "ok" ]; then
  echo "omniroute-normalize: quick_check failed, aborting before write" >&2
  exit 1
fi

count="$(sqlite3 "$db" "SELECT count(*) FROM provider_connections WHERE provider='agy';")"

if [ "${count:-0}" -eq 0 ]; then
  echo "omniroute-normalize: no-op (no agy rows)"
  exit 0
fi

# provider is non-unique (round-robin accounts) so a plain rename is collision-safe.
sqlite3 "$db" "PRAGMA busy_timeout=30000; UPDATE provider_connections SET provider='antigravity' WHERE provider='agy';" >/dev/null

echo "omniroute-normalize: normalized $count agy->antigravity row(s)"
