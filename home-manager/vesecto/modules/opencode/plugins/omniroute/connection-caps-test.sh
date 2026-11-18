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
set -euo pipefail

script="${1:-$(dirname "$0")/connection-caps.sh}"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

db="$fixture/storage.sqlite"
litellm='openai-compatible-chat-4acfd047'
rule='{"status":429,"match":"max_parallel_requests","scope":"model","reason":"rate_limit_exceeded","cooldownMs":15000}'

sqlite3 "$db" <<SQL
CREATE TABLE provider_connections (id TEXT PRIMARY KEY, provider TEXT NOT NULL, provider_specific_data TEXT, max_concurrent INTEGER, rate_limit_overrides_json TEXT);
CREATE TABLE key_value (namespace TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL, PRIMARY KEY (namespace, key));
INSERT INTO provider_connections VALUES
  ('lite', '$litellm', '{"prefix":"litellm"}', NULL, '{"maxWaitMs":1,"rpm":30}'),
  ('ctu', 'openai-compatible-chat-ctu', '{"prefix":"ctu"}', NULL, NULL),
  ('bad', 'broken', 'not json', NULL, NULL);
SQL

run_script() {
    OMNIROUTE_DB="$db" bash "$script"
}

q() {
    sqlite3 "$db" "$1"
}

assert_eq() {
    if [ "$1" != "$2" ]; then
        printf '%s\nexpected: %s\nactual:   %s\n' "$3" "$2" "$1" >&2
        exit 1
    fi
}

run_script >/dev/null
assert_eq "$(q "SELECT max_concurrent || ' ' || rate_limit_overrides_json FROM provider_connections WHERE id='lite';")" '4 {"rpm":30}' 'cap set, only the legacy maxWaitMs=1 dropped'
assert_eq "$(q "SELECT quote(max_concurrent) FROM provider_connections WHERE id IN ('ctu','bad') GROUP BY 1;")" 'NULL' 'non-litellm rows stay uncapped'
assert_eq "$(q "SELECT value FROM key_value WHERE namespace='settings' AND key='providerErrorRules';")" "{\"$litellm\":[$rule]}" 'rule seeded when no rules row exists'

q "UPDATE key_value SET value = '{\"other\":[{\"status\":500,\"match\":\"x\",\"scope\":\"provider\"}],\"$litellm\":[{\"status\":429,\"match\":\"max_parallel_requests\",\"scope\":\"connection\"}]}' WHERE key='providerErrorRules';"
q "UPDATE provider_connections SET rate_limit_overrides_json='{\"maxWaitMs\":1}' WHERE id='lite';"
run_script >/dev/null
assert_eq "$(q "SELECT json_extract(value,'\$.other[0].match') || ' ' || json_extract(value,'\$.\"$litellm\"') FROM key_value WHERE key='providerErrorRules';")" "x [$rule]" 'other providers kept, drifted litellm entry restored'
assert_eq "$(q "SELECT quote(rate_limit_overrides_json) FROM provider_connections WHERE id='lite';")" 'NULL' 'emptied override map returns to NULL'

before="$(q "SELECT value FROM key_value WHERE key='providerErrorRules';")"
output="$(run_script)"
assert_eq "$(q "SELECT value FROM key_value WHERE key='providerErrorRules';")" "$before" 'rerun keeps stored JSON bytes'
assert_eq "$output" "omniroute-caps: no-op (no litellm cap drift found)
omniroute-caps: no-op (max_parallel 429 rule already set for $litellm)" 'rerun reports two no-ops'

q "UPDATE key_value SET value = 'garbage' WHERE key='providerErrorRules';"
if run_script >/dev/null 2>"$fixture/stderr"; then
    printf 'expected refusal on malformed providerErrorRules\n' >&2
    exit 1
fi
assert_eq "$(q "SELECT value FROM key_value WHERE key='providerErrorRules';")" 'garbage' 'malformed rules row left untouched'

printf 'connection-caps tests passed\n'
