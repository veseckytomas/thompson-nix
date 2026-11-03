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

cli="${1:-$(dirname "$0")/diagnostics-cli.sh}"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

db="$fixture/storage.sqlite"
sqlite3 "$db" <<'SQL'
CREATE TABLE call_logs (
  id TEXT PRIMARY KEY,
  timestamp TEXT NOT NULL,
  status INTEGER,
  provider TEXT,
  error_summary TEXT,
  request_body TEXT,
  api_key TEXT
);
CREATE TABLE domain_circuit_breakers (
  name TEXT PRIMARY KEY,
  state TEXT NOT NULL DEFAULT 'CLOSED',
  failure_count INTEGER DEFAULT 0,
  last_failure_time INTEGER,
  options TEXT
);
CREATE TABLE domain_lockout_state (
  identifier TEXT PRIMARY KEY,
  attempts TEXT NOT NULL,
  locked_until INTEGER
);
INSERT INTO domain_circuit_breakers VALUES ('oauth:healthy', 'HEALTHY', 0, NULL, NULL);
INSERT INTO call_logs VALUES
  ('1', '2026-10-26 09:00:00', 200, 'alpha', '', 'SECRET_BODY_1', 'SECRET_KEY_1'),
  ('2', '2026-10-26 10:00:00', 500, 'beta', 'upstream failed', 'SECRET_BODY_2', 'SECRET_KEY_2'),
  ('3', '2026-10-26 11:00:00', 200, 'gamma', 'warning text', 'SECRET_BODY_3', 'SECRET_KEY_3'),
  ('4', '2026-10-26 12:00:00', 204, 'delta', '', 'SECRET_BODY_4', 'SECRET_KEY_4');
SQL

run_cli() {
    OMNIROUTE_DB="$db" bash "$cli" "$@"
}

assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) printf 'expected output to contain: %s\nactual:\n%s\n' "$2" "$1" >&2; exit 1 ;;
    esac
}

assert_excludes() {
    case "$1" in
        *"$2"*) printf 'expected output to exclude: %s\nactual:\n%s\n' "$2" "$1" >&2; exit 1 ;;
        *) ;;
    esac
}

output="$(run_cli logs --lines 2)"
assert_contains "$output" '2026-10-26 12:00:00 | delta | 204 |'
assert_contains "$output" '2026-10-26 11:00:00 | gamma | 200 | warning text'
assert_excludes "$output" '2026-10-26 10:00:00'
assert_excludes "$output" 'SECRET_'

output="$(run_cli logs --lines 10 --filter error)"
assert_contains "$output" '2026-10-26 11:00:00 | gamma | 200 | warning text'
assert_contains "$output" '2026-10-26 10:00:00 | beta | 500 | upstream failed'
assert_excludes "$output" '2026-10-26 12:00:00'

for args in 'logs --lines 0' 'logs --lines nope' 'logs --filter warning' 'logs --bogus' 'health --bogus' 'providers test-all' ''; do
    read -r -a argv <<<"$args"
    if run_cli "${argv[@]}" >"$fixture/stdout" 2>"$fixture/stderr"; then
        printf 'expected failure for: %s\n' "$args" >&2
        exit 1
    fi
done

if OMNIROUTE_DB="$fixture/missing.sqlite" bash "$cli" health >"$fixture/stdout" 2>"$fixture/stderr"; then
    printf 'expected missing database failure\n' >&2
    exit 1
fi
assert_contains "$(<"$fixture/stderr")" 'database not found'

sqlite3 "$db" <<'SQL'
INSERT INTO domain_lockout_state VALUES
  ('provider:null', '[]', NULL),
  ('provider:expired', '[1]', unixepoch('now') * 1000 - 60000);
SQL

output="$(run_cli health)"
assert_contains "$output" 'healthy: no open circuit breakers or active lockouts'
assert_excludes "$output" 'provider:null'
assert_excludes "$output" 'provider:expired'

sqlite3 "$db" <<'SQL'
INSERT INTO domain_circuit_breakers VALUES ('oauth:alpha', 'OPEN', 3, 1793000000, '{"secret":"ignored"}');
INSERT INTO domain_circuit_breakers VALUES ('oauth:closed', 'CLOSED', 0, NULL, NULL);
INSERT INTO domain_lockout_state VALUES ('provider:future', '[2]', unixepoch('now') * 1000 + 600000);
SQL
output="$(run_cli health)"
assert_contains "$output" 'circuit breaker | oauth:alpha | OPEN | 3 | 1793000000'
assert_contains "$output" 'active lockout | provider:future | [2] |'
assert_excludes "$output" 'provider:null'
assert_excludes "$output" 'provider:expired'
assert_excludes "$output" 'oauth:closed'
assert_excludes "$output" 'secret'

output="$(run_cli --help)"
assert_contains "$output" 'omniroute logs'
assert_contains "$output" 'omniroute health'

printf 'diagnostics-cli tests passed\n'
