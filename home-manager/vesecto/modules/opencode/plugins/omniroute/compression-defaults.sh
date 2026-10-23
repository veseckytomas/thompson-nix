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
# Fidelity over ratio for the two engines that mangle what the agent READS; the rest keep compressing.
db="${OMNIROUTE_DB:?OMNIROUTE_DB not set}"

# session-dedup replaces a repeated >=80-char block with "[dedup:ref sha=...]", which reaches the model as lost content, not a reference.
# caveman at level "full" rewrites tool OUTPUT (the "...[truncated]" marker); "lite" keeps the token saving without eating what the agent reads.
desired='{
  "session-dedup": {"enabled": false},
  "caveman": {"enabled": true, "level": "lite"}
}'

# Every call needs the busy timeout: the gateway's PRAGMA journal_mode=WAL on each open briefly locks exclusively.
sq() {
  sqlite3 -cmd ".timeout 30000" "$db" "$@"
}

# json_type() errors on malformed input, so json_valid() must short-circuit ahead of it.
object_guard="json_valid(value) AND json_type(value) = 'object'"

if [ ! -f "$db" ]; then
  echo "omniroute-compression: no database at $db (gateway not initialized yet)"
  exit 0
fi

# Exit 75 (EX_TEMPFAIL) so Restart=on-failure retries instead of marking an unwritten row "done".
if [ "$(sq "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='key_value';")" != "1" ]; then
  echo "omniroute-compression: key_value table absent (gateway not migrated yet)" >&2
  exit 75
fi

# quote() keeps '' and NULL distinguishable from "no malformed row".
malformed="$(sq "SELECT quote(value) FROM key_value WHERE namespace='compression' AND key='engines' AND NOT ($object_guard);")"

if [ -n "$malformed" ]; then
  echo "omniroute-compression: stored value is not a JSON object, refusing to overwrite: $malformed" >&2
  exit 1
fi

desired_c="$(printf '%s' "$desired" | jq -c .)"
escaped="${desired_c//\'/\'\'}"

# json_patch merges per engine, so engines this script does not name keep whatever the gateway set.
changed="$(sq "
INSERT INTO key_value (namespace, key, value)
VALUES ('compression', 'engines', '$escaped')
ON CONFLICT(namespace, key) DO UPDATE SET value = json_patch(
  CASE WHEN $object_guard THEN value ELSE '{}' END, excluded.value)
WHERE value <> json_patch(
  CASE WHEN $object_guard THEN value ELSE '{}' END, excluded.value);
SELECT changes();")"

if [ "$changed" = "0" ]; then
  echo "omniroute-compression: no-op (already provisioned)"
else
  echo "omniroute-compression: disabled session-dedup, set caveman to lite"
fi
