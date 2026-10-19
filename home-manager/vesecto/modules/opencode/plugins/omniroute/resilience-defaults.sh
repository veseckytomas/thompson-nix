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
# Bound cooldown waits instead of disabling them: a short wait rides out a transient
# breaker, while waitForCooldown stays off so nothing can park a request for 300s.
set -euo pipefail

db="${OMNIROUTE_DB:?OMNIROUTE_DB not set}"

# maxRetryWaitMs is derived from maxRetryWaitSec, so writing it would be ignored.
# resetTimeout is the BASE: _openCircuit escalates it by 2^(openCycleCount-3), capped at 16x.
desired='{
  "comboCooldownWait": {"enabled": true, "maxWaitMs": 15000, "maxAttempts": 2, "budgetMs": 30000},
  "waitForCooldown": {"enabled": false, "maxRetries": 10, "maxRetryWaitSec": 300, "budgetMs": 300000},
  "providerBreaker": {
    "oauth": {"failureThreshold": 24, "degradationThreshold": 12, "resetTimeoutMs": 15000},
    "apikey": {"failureThreshold": 24, "degradationThreshold": 12, "resetTimeoutMs": 15000}
  }
}'

# Every call needs the busy timeout: the gateway's PRAGMA journal_mode=WAL on each open briefly locks exclusively.
sq() {
  sqlite3 -cmd ".timeout 30000" "$db" "$@"
}

# json_type() errors on malformed input, so json_valid() must short-circuit ahead of it.
object_guard="json_valid(value) AND json_type(value) = 'object'"

if [ ! -f "$db" ]; then
  echo "omniroute-resilience: no database at $db (gateway not initialized yet)"
  exit 0
fi

# Exit 75 (EX_TEMPFAIL) so Restart=on-failure retries instead of marking an unwritten row "done".
if [ "$(sq "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='key_value';")" != "1" ]; then
  echo "omniroute-resilience: key_value table absent (gateway not migrated yet)" >&2
  exit 75
fi

# quote() keeps '' and NULL distinguishable from "no malformed row".
malformed="$(sq "SELECT quote(value) FROM key_value WHERE namespace='settings' AND key='resilienceSettings' AND NOT ($object_guard);")"

if [ -n "$malformed" ]; then
  echo "omniroute-resilience: stored value is not a JSON object, refusing to overwrite: $malformed" >&2
  exit 1
fi

desired_c="$(printf '%s' "$desired" | jq -c .)"
escaped="${desired_c//\'/\'\'}"

# Merging inside the UPDATE keeps a concurrent gateway write instead of clobbering it with a stale read.
changed="$(sq "
INSERT INTO key_value (namespace, key, value)
VALUES ('settings', 'resilienceSettings', '$escaped')
ON CONFLICT(namespace, key) DO UPDATE SET value = json_patch(
  CASE WHEN $object_guard THEN value ELSE '{}' END, excluded.value)
WHERE value <> json_patch(
  CASE WHEN $object_guard THEN value ELSE '{}' END, excluded.value);
SELECT changes();")"

if [ "$changed" = "0" ]; then
  echo "omniroute-resilience: no-op (already provisioned)"
else
  echo "omniroute-resilience: provisioned 15s cooldown wait + breaker thresholds"
fi
