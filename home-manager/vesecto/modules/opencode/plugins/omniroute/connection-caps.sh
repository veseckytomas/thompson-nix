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
# maxWaitMs=1 fast-fails a full 4-slot pool so the combo picks the next model immediately; 0 inherits the global wait, not zero-wait (2026-11-06).
count="$(sq "SELECT count(*) FROM provider_connections WHERE json_valid(provider_specific_data) AND json_extract(provider_specific_data,'$.prefix')='litellm' AND (max_concurrent IS NULL OR max_concurrent != 4 OR rate_limit_overrides_json IS NULL OR NOT json_valid(rate_limit_overrides_json) OR COALESCE(json_extract(rate_limit_overrides_json,'$.maxWaitMs'),0) != 1);")"

if [ "${count:-0}" -eq 0 ]; then
  echo "omniroute-caps: no-op (no litellm cap drift found)"
  exit 0
fi

# json_set preserves other operator overrides while Nix owns cap + maxWaitMs.
sq "UPDATE provider_connections SET max_concurrent=4,
  rate_limit_overrides_json=json_set(CASE WHEN json_valid(rate_limit_overrides_json) THEN rate_limit_overrides_json ELSE '{}' END,'$.maxWaitMs',1)
  WHERE json_valid(provider_specific_data) AND json_extract(provider_specific_data,'$.prefix')='litellm';" >/dev/null

echo "omniroute-caps: set $count litellm row(s) to cap 4 + maxWaitMs 1"
