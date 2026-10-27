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
set -euo pipefail

script="${1:-$(dirname "$0")/resilience-defaults.sh}"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

db="$fixture/storage.sqlite"
sqlite3 "$db" 'CREATE TABLE key_value (namespace TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY (namespace, key));'

run_script() {
    OMNIROUTE_DB="$db" bash "$script"
}

read_settings() {
    sqlite3 "$db" "SELECT value FROM key_value WHERE namespace='settings' AND key='resilienceSettings';"
}

assert_json() {
    local json="$1" filter="$2"
    if ! jq -e "$filter" >/dev/null <<<"$json"; then
        printf 'expected JSON assertion: %s\nactual:\n%s\n' "$filter" "$json" >&2
        exit 1
    fi
}

run_script >/dev/null
settings="$(read_settings)"
assert_json "$settings" '.providerBreaker.apikey == {"failureThreshold": 4, "degradationThreshold": 2, "resetTimeoutMs": 60000}'
assert_json "$settings" '.providerBreaker.oauth == {"failureThreshold": 24, "degradationThreshold": 12, "resetTimeoutMs": 15000}'

sqlite3 "$db" <<'SQL'
UPDATE key_value SET value = '{
  "unrelated": {"keep": true},
  "providerBreaker": {
    "custom": {"keep": "yes"},
    "oauth": {"failureThreshold": 1, "degradationThreshold": 1, "resetTimeoutMs": 1, "extra": "preserved"},
    "apikey": {"failureThreshold": 1, "degradationThreshold": 1, "resetTimeoutMs": 1, "extra": "preserved"}
  }
}' WHERE namespace='settings' AND key='resilienceSettings';
SQL
run_script >/dev/null
settings="$(read_settings)"
assert_json "$settings" '.unrelated.keep == true and .providerBreaker.custom.keep == "yes"'
assert_json "$settings" '.providerBreaker.apikey == {"failureThreshold": 4, "degradationThreshold": 2, "resetTimeoutMs": 60000, "extra": "preserved"}'
assert_json "$settings" '.providerBreaker.oauth == {"failureThreshold": 24, "degradationThreshold": 12, "resetTimeoutMs": 15000, "extra": "preserved"}'

before="$settings"
output="$(run_script)"
after="$(read_settings)"
if [ "$after" != "$before" ]; then
    printf 'expected idempotent rerun to preserve stored JSON bytes\nbefore:\n%s\nafter:\n%s\n' "$before" "$after" >&2
    exit 1
fi
if [ "$output" != 'omniroute-resilience: no-op (already provisioned)' ]; then
    printf 'expected idempotent no-op status\nactual:\n%s\n' "$output" >&2
    exit 1
fi

printf 'resilience-defaults tests passed\n'
