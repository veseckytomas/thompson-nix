#!/usr/bin/env bash
#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / /_/ (__  ) /_/ / / / /
# / / / / / / /_/ / /_/ / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
# Seed litellm/kimi-k3 thinking_effort vocab: upstream parser truncates "max" (comma edge), so seed kimi's own accepted vocab.
set -euo pipefail

db="${OMNIROUTE_DB:?OMNIROUTE_DB not set}"

if [ ! -f "$db" ]; then
    echo "omniroute-kimi-effort: no database at $db (not connected yet)"
    exit 0
fi

# Every call needs busy timeout because gateway's WAL pragma briefly locks startup.
sq() {
    sqlite3 -cmd ".timeout 30000" "$db" "$1"
}

# Exit 75 = EX_TEMPFAIL: Restart=on-failure retries after gateway migration.
if [ "$(sq "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='model_capability_overrides';")" != "1" ]; then
    echo "omniroute-kimi-effort: model_capability_overrides table absent (gateway not migrated yet)" >&2
    exit 75
fi

count="$(sq "SELECT count(*) FROM model_capability_overrides WHERE provider='litellm' AND model_id='kimi-k3' AND override_key='reasoning_efforts';")"

if [ "${count:-0}" -eq 0 ]; then
    # Value = kimi's own accepted vocabulary, verbatim from its 400 ("accepts only low/high/max").
    sq "INSERT INTO model_capability_overrides (provider, model_id, override_key, override_value, refreshed_at)
        VALUES ('litellm', 'kimi-k3', 'reasoning_efforts', '[\"low\",\"high\",\"max\"]', datetime('now'));" >/dev/null
    echo "omniroute-kimi-effort: seeded litellm/kimi-k3 reasoning_efforts=[low,high,max] row"
    exit 0
fi

echo "omniroute-kimi-effort: no-op ($(sq "SELECT override_value FROM model_capability_overrides WHERE provider='litellm' AND model_id='kimi-k3' AND override_key='reasoning_efforts';"))"
