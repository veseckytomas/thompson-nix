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

usage() {
    cat <<'EOF'
Usage:
  omniroute logs [--lines N] [--filter error]
  omniroute health

This wrapper exposes only read-only logs and health diagnostics.
EOF
}

fail() {
    printf 'omniroute: %s\n' "$1" >&2
    usage >&2
    exit 2
}

open_db() {
    db="${OMNIROUTE_DB:-${XDG_DATA_HOME:-$HOME/.local/share}/omniroute/data/storage.sqlite}"
    [ -f "$db" ] || fail "database not found: $db"
    db_uri="file:$db?mode=ro"
}

logs() {
    lines=30
    filter=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --lines)
                [ $# -ge 2 ] || fail '--lines requires a positive integer'
                case "$2" in
                    '' | *[!0-9]* | 0) fail '--lines requires a positive integer' ;;
                esac
                lines="$2"
                shift 2
                ;;
            --filter)
                [ $# -ge 2 ] || fail '--filter requires error'
                [ "$2" = error ] || fail '--filter accepts only error'
                filter=error
                shift 2
                ;;
            *) fail "unknown logs argument: $1" ;;
        esac
    done

    open_db
    where=""
    [ "$filter" != error ] || where="WHERE status NOT BETWEEN 200 AND 299 OR length(trim(coalesce(error_summary, ''))) > 0"
    sqlite3 -readonly -separator ' | ' "$db_uri" "SELECT timestamp, coalesce(provider, ''), coalesce(status, ''), coalesce(error_summary, '') FROM call_logs $where ORDER BY timestamp DESC LIMIT $lines;"
}

health() {
    [ $# -eq 0 ] || fail "unknown health argument: $1"
    open_db
    output="$(sqlite3 -readonly -separator ' | ' "$db_uri" "SELECT 'circuit breaker', name, state, coalesce(failure_count, 0), coalesce(last_failure_time, '') FROM domain_circuit_breakers WHERE upper(state) NOT IN ('CLOSED', 'HEALTHY') ORDER BY name; SELECT 'active lockout', identifier, attempts, locked_until FROM domain_lockout_state WHERE locked_until IS NOT NULL AND CAST(locked_until AS INTEGER) > unixepoch('now') * 1000 ORDER BY identifier;")"
    if [ -n "$output" ]; then
        printf '%s\n' "$output"
    else
        printf 'healthy: no open circuit breakers or active lockouts\n'
    fi
}

case "${1:-}" in
    logs) shift; logs "$@" ;;
    health) shift; health "$@" ;;
    -h | --help) usage ;;
    '') fail 'missing subcommand; choose logs or health' ;;
    *) fail "unknown subcommand: $1; this wrapper exposes only logs and health" ;;
esac
