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
# Raise the cooldown-aware retry bounds to their ceilings so a 429 cooldown parks
# the request instead of killing the agent; omniroute ships 90s/5 and the values
# are only reachable by writing the DB (the API's zod schema caps maxWaitMs at 30s).
set -euo pipefail

db="${OMNIROUTE_DB:?OMNIROUTE_DB not set}"

# maxRetryWaitMs is derived from maxRetryWaitSec, so writing it would be ignored.
desired='{
  "comboCooldownWait": {"enabled": true, "maxWaitMs": 300000, "maxAttempts": 10, "budgetMs": 300000},
  "waitForCooldown": {"enabled": true, "maxRetries": 10, "maxRetryWaitSec": 300, "budgetMs": 300000}
}'

if [ ! -f "$db" ]; then
  echo "omniroute-resilience: no database at $db (gateway not initialized yet)"
  exit 0
fi

if [ "$(sqlite3 "$db" 'PRAGMA quick_check;')" != "ok" ]; then
  echo "omniroute-resilience: quick_check failed, aborting before write" >&2
  exit 1
fi

# .timeout sets the busy timeout silently; -cmd "PRAGMA ..." would emit it as a result row.
current="$(sqlite3 -cmd ".timeout 30000" "$db" "SELECT value FROM key_value WHERE namespace='settings' AND key='resilienceSettings';")"
[ -n "$current" ] || current='{}'

# Shallow merge keeps any sibling sub-objects a future omniroute version adds.
next="$(printf '%s' "$current" | jq -c --argjson d "$desired" '. * $d')"

if [ "$next" = "$(printf '%s' "$current" | jq -c '.')" ]; then
  echo "omniroute-resilience: no-op (already provisioned)"
  exit 0
fi

escaped="${next//\'/\'\'}"

sqlite3 -cmd ".timeout 30000" "$db" "
INSERT INTO key_value (namespace, key, value)
VALUES ('settings', 'resilienceSettings', '$escaped')
ON CONFLICT(namespace, key) DO UPDATE SET value = excluded.value;" >/dev/null

echo "omniroute-resilience: provisioned 300s cooldown wait bounds"
