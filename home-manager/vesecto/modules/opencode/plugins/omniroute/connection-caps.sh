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
# Idempotently set max_concurrent=4 on e-infra litellm connections: e-infra allows 4 concurrent per user (docs.cerit.io).
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
# Drift also covers a leftover maxWaitMs=1 from the removed 1ms fast-fail; the CASE keeps json_extract off malformed overrides.
count="$(sq "SELECT count(*) FROM provider_connections WHERE json_valid(provider_specific_data) AND json_extract(provider_specific_data,'$.prefix')='litellm' AND (max_concurrent IS NULL OR max_concurrent != 4 OR CASE WHEN json_valid(rate_limit_overrides_json) THEN COALESCE(json_extract(rate_limit_overrides_json,'$.maxWaitMs'),0) = 1 ELSE 0 END);")"

if [ "${count:-0}" -eq 0 ]; then
  echo "omniroute-caps: no-op (no litellm cap drift found)"
else
  # Only the legacy maxWaitMs=1 is dropped; other operator overrides survive, and an emptied map goes back to NULL.
  sq "UPDATE provider_connections SET max_concurrent=4,
    rate_limit_overrides_json=CASE WHEN json_valid(rate_limit_overrides_json) AND COALESCE(json_extract(rate_limit_overrides_json,'$.maxWaitMs'),0) = 1
      THEN NULLIF(json_remove(rate_limit_overrides_json,'$.maxWaitMs'),'{}') ELSE rate_limit_overrides_json END
    WHERE json_valid(provider_specific_data) AND json_extract(provider_specific_data,'$.prefix')='litellm';" >/dev/null
  echo "omniroute-caps: set $count litellm row(s) to cap 4, legacy maxWaitMs 1 cleared"
fi

# e-infra's max_parallel 429 sends retry-after: 18000, which otherwise locks the model for 5 h; Nix owns the litellm entry like the cap.
rules='[{"status":429,"match":"max_parallel_requests","scope":"model","reason":"rate_limit_exceeded","cooldownMs":15000}]'

# quote() keeps '' and NULL distinguishable from "no malformed row".
malformed="$(sq "SELECT quote(value) FROM key_value WHERE namespace='settings' AND key='providerErrorRules' AND NOT (json_valid(value) AND json_type(value) = 'object');")"
if [ -n "$malformed" ]; then
  echo "omniroute-caps: providerErrorRules is not a JSON object, refusing to overwrite: $malformed" >&2
  exit 1
fi

sq "SELECT DISTINCT provider FROM provider_connections WHERE json_valid(provider_specific_data) AND json_extract(provider_specific_data,'$.prefix')='litellm';" |
  while IFS= read -r provider; do
    # The id is spliced into a SQL literal and a JSON path, so only a plain id is accepted.
    if ! [[ $provider =~ ^[A-Za-z0-9._-]+$ ]]; then
      echo "omniroute-caps: unexpected litellm provider id, refusing: $provider" >&2
      exit 1
    fi
    jpath="\$.\"$provider\""
    # Merging inside the UPDATE keeps a concurrent gateway write instead of clobbering it with a stale read.
    changed="$(sq "
      INSERT INTO key_value (namespace, key, value) VALUES ('settings', 'providerErrorRules', json_object('$provider', json('$rules')))
      ON CONFLICT(namespace, key) DO UPDATE SET value = json_set(value, '$jpath', json('$rules'))
      WHERE value <> json_set(value, '$jpath', json('$rules'));
      SELECT changes();")"
    if [ "$changed" = "0" ]; then
      echo "omniroute-caps: no-op (max_parallel 429 rule already set for $provider)"
    else
      echo "omniroute-caps: set 15 s max_parallel 429 rule for $provider"
    fi
  done
