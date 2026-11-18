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
# S1-S5 for the litellm fail-fast fix on a throwaway namespaced gateway; --baseline runs it unpatched and must fail.

if [ "${1:-}" != "--inside" ]; then
  baseline=0
  case "${1:-}" in
    --baseline) baseline=1 ;;
    "") ;;
    *) echo "usage: omniroute-e2e [--baseline]" >&2; exit 2 ;;
  esac
  pkg="$(readlink -f "$HOME/.local/share/omniroute/current")"
  [ -f "$pkg/node_modules/omniroute/bin/omniroute.mjs" ] || { echo "omniroute-e2e: no installed gateway under $pkg" >&2; exit 1; }
  work="$(mktemp -d -t omniroute-e2e.XXXXXX)"
  # The kernel leaves the overlay workdir at mode 000, so rm needs the chmod first.
  trap 'chmod -R u+rwX "$work" || true; rm -rf "$work"' EXIT
  # A private pid namespace under --kill-child takes the gateway and both mocks down with this script.
  unshare --user --map-root-user --mount --net --pid --fork --kill-child --mount-proc \
    env E2E_PKG="$pkg" E2E_WORK="$work" E2E_BASELINE="$baseline" bash "$0" --inside
  exit $?
fi

pkg="${E2E_PKG:?}" work="${E2E_WORK:?}" baseline="${E2E_BASELINE:?}"
gw=http://127.0.0.1:20128 lite=http://127.0.0.1:18001 next=http://127.0.0.1:18002
fails=0
mapfile -t gateway_env <<<"$E2E_GATEWAY_ENV"
ip link set lo up
mkdir -p "$work/upper" "$work/ovl" "$work/data" "$work/home" "$work/logs"
mount -t overlay overlay -o "lowerdir=$pkg,upperdir=$work/upper,workdir=$work/ovl" "$pkg"

log() { printf '%s\n' "$*"; }
pass() { log "PASS $1: $2"; }
fail() { log "FAIL $1: $2"; fails=$((fails + 1)); }
api() { curl -sS --max-time 30 -H 'Content-Type: application/json' "$@"; }
# Setup must not half-succeed: print the server's reason and abort on any non-2xx.
setup() {
  local out code
  out="$(api -w '\n%{http_code}' "$@")"
  code="${out##*$'\n'}"
  out="${out%$'\n'*}"
  if [ "${code:0:1}" != 2 ]; then
    echo "omniroute-e2e: setup call $* failed with $code: $out" >&2
    exit 1
  fi
  printf '%s' "$out"
}
ctl() { api -o /dev/null -X POST -d "$2" "$1/__ctl"; }
stat_of() { api "$1/__stats" | jq -r "$2"; }
sq() { sqlite3 -cmd '.timeout 30000' "$work/data/storage.sqlite" "$@"; }
under() { awk "BEGIN { exit !($1 < $2) }"; }
# Prints "http_code seconds served_by" for one chat request, on the litellm-first test chain by default.
chat() {
  local body out
  body="$(mktemp -p "$work")"
  out="$(api -o "$body" -w '%{http_code} %{time_total}' -d "{\"model\":\"${1:-e2e-chain}\",\"stream\":false,\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}]}" "$gw/v1/chat/completions")"
  printf '%s %s\n' "$out" "$(jq -r '.choices[0].message.content // "none"' "$body" 2>/dev/null || echo none)"
}
# The mock exposes state, not events, so the harness polls its in-flight count, bounded at 10 s.
await_litellm_inflight() {
  for _ in $(seq 100); do
    [ "$(stat_of "$lite" .inflight)" -eq "$1" ] && return 0
    sleep 0.1
  done
  return 1
}
hold_pool() {
  ctl "$lite" '{"hold":true}'
  for _ in 1 2 3 4; do
    api -N -o /dev/null --max-time 120 -d '{"model":"e2e-chain","stream":true,"messages":[{"role":"user","content":"hold"}]}' "$gw/v1/chat/completions" &
  done
  await_litellm_inflight 4
}
release_pool() {
  ctl "$lite" '{"hold":false}'
  await_litellm_inflight 0
}

start_gateway() {
  # The gateway also reads an env file from its cwd, so it starts from the throwaway home.
  (cd "$work/home" && exec env -i HOME="$work/home" DATA_DIR="$work/data" OMNIROUTE_DISABLE_BACKGROUND_SERVICES=true \
    OMNIROUTE_CLI_SKIP_DEFAULT_DATA_ENV=1 OMNIROUTE_CLI_SKIP_REPO_ENV=1 "${gateway_env[@]}" \
    "$E2E_NODE" "$pkg/node_modules/omniroute/bin/omniroute.mjs" >>"$work/logs/gateway.log" 2>&1) &
  gateway_pid=$!
  for _ in $(seq 180); do
    curl -sf --max-time 2 "$gw/api/monitoring/health" >/dev/null && return 0
    sleep 1
  done
  echo "omniroute-e2e: gateway never became healthy" >&2
  tail -40 "$work/logs/gateway.log" >&2
  exit 1
}
stop_gateway() {
  kill "$gateway_pid" || true
  wait "$gateway_pid" || true
  for _ in $(seq 50); do
    curl -sf --max-time 1 "$gw/api/monitoring/health" >/dev/null || return 0
    sleep 0.2
  done
}

python3 "$E2E_MOCK" 18001 e-infra kimi-k3 >"$work/logs/mock-litellm.log" 2>&1 &
python3 "$E2E_MOCK" 18002 next m1 >"$work/logs/mock-next.log" 2>&1 &

# A fresh install without a password leaves loopback unauthenticated until onboarding completes, which this never does.
start_gateway
node_id() {
  setup -X POST -d "{\"name\":\"$1\",\"prefix\":\"$1\",\"apiType\":\"chat\",\"baseUrl\":\"$2/v1\",\"type\":\"openai-compatible\"}" "$gw/api/provider-nodes" | jq -er .node.id
}
lite_id="$(node_id litellm "$lite")"
next_id="$(node_id nexthop "$next")"
setup -o /dev/null -X POST -d "{\"provider\":\"$lite_id\",\"apiKey\":\"sk-e2e-lite\",\"name\":\"e2e-lite\",\"providerSpecificData\":{\"prefix\":\"litellm\"}}" "$gw/api/providers"
setup -o /dev/null -X POST -d "{\"provider\":\"$next_id\",\"apiKey\":\"sk-e2e-next\",\"name\":\"e2e-next\",\"providerSpecificData\":{\"prefix\":\"nexthop\"}}" "$gw/api/providers"
setup -o /dev/null -X POST -d '{"name":"e2e-chain","strategy":"priority","models":["litellm/kimi-k3","nexthop/m1"]}' "$gw/api/combos"
stop_gateway

# Mirrors the live litellm row, then the units Home Manager runs before every gateway start.
sq "UPDATE provider_connections SET rate_limit_protection=1 WHERE provider='$lite_id';"
OMNIROUTE_DB="$work/data/storage.sqlite" bash "$E2E_RESILIENCE"
if [ "$baseline" = 0 ]; then
  OMNIROUTE_DB="$work/data/storage.sqlite" bash "$E2E_CAPS"
  python3 "$E2E_PATCHER" "$pkg/node_modules/omniroute"
  python3 "$E2E_RULES_PATCHER" "$pkg/node_modules/omniroute"
else
  sq "UPDATE provider_connections SET max_concurrent=4 WHERE provider='$lite_id';"
fi
start_gateway
log "omniroute-e2e: $([ "$baseline" = 1 ] && echo 'BASELINE (unpatched, no 429 rule)' || echo patched) gateway up, litellm cap $(sq "SELECT max_concurrent FROM provider_connections WHERE provider='$lite_id';")"

read -r code secs by <<<"$(chat)"
if [ "$code" = 200 ] && [ "$by" = "from e-infra" ]; then
  pass S1 "idle pool served by litellm in ${secs}s"
else
  fail S1 "got $code from '$by' in ${secs}s"
fi

if hold_pool; then
  read -r code secs by <<<"$(chat)"
  if [ "$code" = 200 ] && [ "$by" = "from next" ] && under "$secs" 5; then
    pass S2 "full pool skipped to the next member in ${secs}s"
  else
    fail S2 "got $code from '$by' in ${secs}s"
  fi
  pids=()
  for _ in $(seq 8); do
    chat >>"$work/burst" &
    pids+=("$!")
  done
  wait "${pids[@]}"
  on_next="$(grep -c 'from next$' "$work/burst" || true)"
  slowest="$(awk '$2 > m { m = $2 } END { print m + 0 }' "$work/burst")"
  peak="$(stat_of "$lite" .max_inflight)"
  if [ "$on_next" = 8 ] && [ "$peak" -le 4 ] && under "$slowest" 5; then
    pass S2b "8 concurrent on a full pool all went to the next member, slowest ${slowest}s, litellm peak $peak"
  else
    fail S2b "$on_next/8 on the next member, slowest ${slowest}s, litellm peak $peak"
  fi
else
  fail S2 "could not fill the 4 litellm slots"
fi
release_pool || fail S2 "held litellm streams did not drain"

read -r code secs by <<<"$(chat)"
open="$(sq "SELECT count(*) FROM domain_circuit_breakers WHERE state <> 'CLOSED' AND (name LIKE 'litellm%' OR name LIKE '%$lite_id%');")"
if [ "$code" = 200 ] && [ "$by" = "from e-infra" ] && [ "$open" = 0 ]; then
  pass S3 "freed slot back on litellm in ${secs}s, no open litellm breaker"
else
  fail S3 "got $code from '$by' in ${secs}s, $open open litellm breaker(s)"
fi

if hold_pool; then
  chat litellm/kimi-k3 >"$work/pinned" &
  pinned=$!
  # Freeing a slot inside the 4 s queue budget: a pinned request must still be waiting for it then.
  sleep 2
  release_pool || fail S4 "held litellm streams did not drain"
  wait "$pinned"
  read -r code secs by <"$work/pinned"
  if [ "$code" = 200 ] && [ "$by" = "from e-infra" ] && ! under "$secs" 1.5; then
    pass S4 "pinned litellm request waited ${secs}s for its slot instead of failing"
  else
    fail S4 "pinned request got $code from '$by' in ${secs}s"
  fi
else
  fail S4 "could not fill the 4 litellm slots"
fi

ctl "$lite" '{"fail429":1}'
read -r code secs by <<<"$(chat)"
if [ "$code" = 200 ] && [ "$by" = "from next" ] && under "$secs" 5; then
  pass S5a "max_parallel 429 advanced the chain in ${secs}s"
else
  fail S5a "429 turn got $code from '$by' in ${secs}s"
fi
started=$SECONDS
recovered=""
while [ $((SECONDS - started)) -lt 60 ]; do
  read -r code secs by <<<"$(chat)"
  if [ "$by" = "from e-infra" ]; then
    recovered=$((SECONDS - started))
    break
  fi
  sleep 1
done
if [ -n "$recovered" ]; then
  pass S5b "litellm served again ${recovered}s after the 429, whose retry-after asked for 5 h"
else
  fail S5b "litellm still locked out 60s after the 429"
fi

stop_gateway
log "omniroute-e2e: $fails failure(s); litellm call_logs by outcome:"
sq "SELECT '  ' || status || ' ' || coalesce(substr(error_summary, 1, 70), '') || ' x' || count(*) FROM call_logs WHERE provider='$lite_id' GROUP BY status, substr(error_summary, 1, 70);"
log "omniroute-e2e: first litellm lockout decisions and runtime-settings loads:"
jq -rR --arg id "$lite_id" 'fromjson? | (.message // .msg // "") | select(test("Model-only lockout|HOT_RELOAD|providerErrorRules|RATE-LIMIT\\] .*429"; "i"))
  | "  " + .[0:240]' "$work/data/logs/application/app.log" | head -12 || true
grep -E 'HOT_RELOAD|Runtime settings|providerErrorRules' "$work/logs/gateway.log" | head -6 | sed 's/^/  /' || true
exit $((fails > 0))
