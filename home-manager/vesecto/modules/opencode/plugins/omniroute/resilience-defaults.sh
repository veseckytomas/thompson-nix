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
  echo "omniroute-resilience: provisioned 300s cooldown wait bounds"
fi
