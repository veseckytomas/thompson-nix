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

patcher="${1:-$(dirname "$0")/patch-semaphore-failfast.py}"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

chunks="$fixture/pkg/dist/.build/next/server/chunks"
mkdir -p "$chunks"

# Mirrors 3.8.53's minified chatCore -> deps literal -> executeProviderRequest -> acquireMany, with per-copy identifiers.
write_chunk() {
    local file="$1" combo="$2" el="$3" pc="$4" ak="$5" ac="$6" mg="$7"
    cat >"$chunks/$file" <<JS
"use strict";
let captured=null;
const acquire=(reqs,opts)=>{captured={reqs,opts};return Promise.resolve(()=>{})};
async function core({isCombo:$combo=!1,settings:S={}}){let deps={agentGoalPolicy:null,assertManagedLeaseFence:null,settings:S};return D(deps,"m",!1,null)}
async function D(e,t=e.effectiveModel,r=!1,h){let{agentGoalPolicy:P,assertManagedLeaseFence:j,settings:Q}=e;{let $el=Q,pk="p",$pc=Q.pc,$ak=Q.ak,$ac=Q.ac,$mg=Q.mg,ep={signal:null},B=4000;await acquire([{key:"global",maxConcurrency:$el.requestQueue.globalConcurrentRequests},{key:\`provider:\${pk}\`,maxConcurrency:$pc},{key:$ak||"",maxConcurrency:$ak?$ac:null},{key:$mg.key||"",maxConcurrency:$mg.key?$mg.maxConcurrency:null}],{timeoutMs:B,maxQueueSize:$el.requestQueue.maxQueueDepth,signal:ep.signal})}return captured}
module.exports={core};
JS
}
write_chunk a._.js rr el D h f S
write_chunk b._.js ro ec j v y I
printf 'module.exports=1;\n' >"$chunks/unrelated._.js"
cp -r "$fixture/pkg" "$fixture/pristine"
pristine="$fixture/pristine/dist/.build/next/server/chunks"

run_patcher() {
    python3 "$patcher" "$1"
}

assert_eq() {
    if [ "$1" != "$2" ]; then
        printf '%s\nexpected: %s\nactual:   %s\n' "$3" "$2" "$1" >&2
        exit 1
    fi
}

expect_failure() {
    local label="$1" message="$2"
    shift 2
    if "$@" >/dev/null 2>"$fixture/stderr"; then
        printf 'expected failure: %s\n' "$label" >&2
        exit 1
    fi
    if ! grep -qF "$message" "$fixture/stderr"; then
        printf '%s: expected stderr to contain: %s\nactual:\n%s\n' "$label" "$message" "$(<"$fixture/stderr")" >&2
        exit 1
    fi
}

# Row: isCombo, globalConcurrentRequests, providerConcurrency, account key, account cap, model gate, expected failFast.
decision_table() {
    node - "$1" <<'JS'
const file = process.argv[2];
const { core } = require(file);
const noModel = { key: null, maxConcurrency: null };
const rows = [
  [true, 0, 0, "acct", 4, noModel, true, "combo with only the account gate active"],
  [false, 0, 0, "acct", 4, noModel, false, "pinned request keeps queueing"],
  [true, 0, 0, "acct", null, noModel, false, "uncapped account"],
  [true, 0, 0, null, 4, noModel, false, "no account key"],
  [true, 8, 0, "acct", 4, noModel, false, "global gate active"],
  [true, 0, 2, "acct", 4, noModel, false, "provider gate active"],
  [true, 0, 0, "acct", 4, { key: "m", maxConcurrency: 1 }, false, "model gate active"],
  [true, 0, 0, "acct", 4, { key: "m", maxConcurrency: null }, true, "model key without a cap is bypassed"],
];
(async () => {
  for (const [isCombo, global, pc, ak, ac, mg, want, label] of rows) {
    const settings = { requestQueue: { globalConcurrentRequests: global, maxQueueDepth: 0 }, pc, ak, ac, mg };
    const got = await core({ isCombo, settings });
    if (got.opts.failFast !== want) {
      console.error(`${file}: ${label}: failFast=${got.opts.failFast}, want ${want}`);
      process.exit(1);
    }
  }
})();
JS
}

# The table must be able to fail: the unpatched gate never sets failFast.
expect_failure 'decision table on an unpatched chunk' 'combo with only the account gate active' decision_table "$pristine/a._.js"

assert_eq "$(run_patcher "$fixture/pkg")" 'patch-semaphore-failfast: OK applied (2 of 2 chunks)' 'first run patches both gate chunks'
decision_table "$chunks/a._.js"
decision_table "$chunks/b._.js"
cmp "$chunks/unrelated._.js" "$pristine/unrelated._.js"

before="$(cat "$chunks"/*.js | sha256sum)"
assert_eq "$(run_patcher "$fixture/pkg")" 'patch-semaphore-failfast: OK already applied (2 chunks)' 'second run is a no-op'
assert_eq "$(cat "$chunks"/*.js | sha256sum)" "$before" 'second run leaves bytes alone'

# A drifted chunk aborts before any file is written.
cp -r "$fixture/pristine" "$fixture/drift"
sed -i 's/maxQueueSize:/maxQueueLen:/' "$fixture/drift/dist/.build/next/server/chunks/b._.js"
expect_failure 'drifted gate' 'concurrency gate anchor not unique in b._.js (0 hits)' run_patcher "$fixture/drift"
cmp "$fixture/drift/dist/.build/next/server/chunks/a._.js" "$pristine/a._.js"

cp -r "$fixture/pristine" "$fixture/drift2"
sed -i 's/isCombo:ro=!1,/isCombo:ro=!0,/' "$fixture/drift2/dist/.build/next/server/chunks/b._.js"
expect_failure 'drifted isCombo param' 'isCombo param anchor not unique in b._.js (0 hits)' run_patcher "$fixture/drift2"
cmp "$fixture/drift2/dist/.build/next/server/chunks/a._.js" "$pristine/a._.js"

expect_failure 'missing compiled server' 'vanished upstream' run_patcher "$fixture/nowhere"

# An interrupted earlier run left one chunk patched; the rerun finishes the rest.
cp -r "$fixture/pristine" "$fixture/partial"
cp "$chunks/a._.js" "$fixture/partial/dist/.build/next/server/chunks/a._.js"
assert_eq "$(run_patcher "$fixture/partial")" 'patch-semaphore-failfast: OK applied (1 of 2 chunks)' 'partial tree is completed'
decision_table "$fixture/partial/dist/.build/next/server/chunks/b._.js"

# The real anchors live only in the installed package, which the build sandbox lacks.
real="${OMNIROUTE_PKG:-$HOME/.local/share/omniroute/current/node_modules/omniroute}"
if [ -d "$real/dist/.build/next/server" ]; then
    copy="$fixture/real/dist/.build/next/server/chunks"
    mkdir -p "$copy"
    grep -rlF --include='*.js' 'requestQueue.maxQueueDepth,signal:' "$real/dist/.build/next/server" | xargs -I{} cp {} "$copy/"
    run_patcher "$fixture/real" >/dev/null
    for f in "$copy"/*.js; do
        node --check "$f"
        assert_eq "$(grep -o '__omniCombo' "$f" | wc -l)" 3 "$(basename "$f"): marker in deps, destructure and gate"
    done
    printf 'installed package: %s gate chunks patch cleanly and parse\n' "$(find "$copy" -name '*.js' | wc -l)"
fi

printf 'patch-semaphore-failfast tests passed\n'
