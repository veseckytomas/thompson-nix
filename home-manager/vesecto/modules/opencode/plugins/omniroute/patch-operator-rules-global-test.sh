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

patcher="${1:-$(dirname "$0")/patch-operator-rules-global.py}"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

chunks="$fixture/pkg/dist/.build/next/server/chunks"
mkdir -p "$chunks"

# Mirrors 3.8.54's configured-rule store beside an operator-default store that must not be shared.
write_chunk() {
    local file="$1" store="$2" factory="$3"
    cat >"$chunks/$file" <<JS
"use strict";
module.exports=(()=>{var t;let r,n,\$default={},${store}={};function $factory(){return[{id:"minimax-per-model-quota",match:()=>null}]}function b(e){if(!e)return!1;let t=${store}[e.toLowerCase()];return!!t&&t.length>0}function w(e,t,r,n,s){if(!e)return null;let i=e.toLowerCase(),a=(s??$store)?.[i];if(a&&a.length>0){let e=("string"==typeof n?n:JSON.stringify(n??"")).toLowerCase();for(let r of a)if(r.status===t&&e.includes(r.match.toLowerCase()))return{reason:r.reason??"quota_exhausted",scope:r.scope,cooldownMs:r.cooldownMs}}return null}return{has:b,match:w,defaults:function(){return \$default},set:function(e){if($store={},e)for(let[t,r]of Object.entries(e))Array.isArray(r)&&r.length>0&&(${store}[t.toLowerCase()]=r)}}})();
JS
}
write_chunk a._.js o s
write_chunk b._.js q i
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

# Copy a is the boot hot-reload's, copy b the chat route's: a rule set through a must be what b matches.
shared_rules() {
    node - "$1" "$2" <<'JS'
const [a, b] = process.argv.slice(2).map((file) => require(file));
const rule = [{ status: 429, match: "max_parallel_requests", scope: "model", cooldownMs: 15000 }];
const body = "Rate limit exceeded. Limit type: max_parallel_requests. Current limit: 4";
const fail = (message) => {
  console.error(message);
  process.exit(1);
};
a.set({ "Litellm-X": rule });
const hit = b.match("litellm-x", 429, null, body);
if (!b.has("litellm-x") || hit?.cooldownMs !== 15000) {
  fail(`rules set through one module copy are invisible to the other: ${JSON.stringify(hit)}`);
}
b.set({ other: rule });
if (a.has("litellm-x") || !a.has("other")) fail("a later set must replace the shared rules, not merge into them");
a.set(null);
if (b.has("other")) fail("clearing through one copy must clear the other");
a.defaults().other = rule;
if (b.has("other")) fail("operator defaults must remain module-local");
JS
}

# The check must be able to fail: unpatched copies keep separate stores.
expect_failure 'shared store on unpatched chunks' 'invisible to the other' shared_rules "$pristine/a._.js" "$pristine/b._.js"

assert_eq "$(run_patcher "$fixture/pkg")" 'patch-operator-rules-global: OK applied (2 of 2 chunks)' 'first run patches both rule chunks'
shared_rules "$chunks/a._.js" "$chunks/b._.js"
cmp "$chunks/unrelated._.js" "$pristine/unrelated._.js"

before="$(cat "$chunks"/*.js | sha256sum)"
assert_eq "$(run_patcher "$fixture/pkg")" 'patch-operator-rules-global: OK already applied (2 chunks)' 'second run is a no-op'
assert_eq "$(cat "$chunks"/*.js | sha256sum)" "$before" 'second run leaves bytes alone'

# A drifted chunk aborts before any file is written.
cp -r "$fixture/pristine" "$fixture/drift"
sed -i 's/,q={};/,q=Object.create(null);/' "$fixture/drift/dist/.build/next/server/chunks/b._.js"
expect_failure 'drifted declaration' 'rule store declaration anchor not unique in b._.js (0 hits)' run_patcher "$fixture/drift"
cmp "$fixture/drift/dist/.build/next/server/chunks/a._.js" "$pristine/a._.js"

cp -r "$fixture/pristine" "$fixture/drift2"
sed -i 's/if(q={},e)/if(q=Object.create(null),e)/' "$fixture/drift2/dist/.build/next/server/chunks/b._.js"
expect_failure 'drifted setter' 'rule store setter anchor not unique in b._.js (0 hits)' run_patcher "$fixture/drift2"
cmp "$fixture/drift2/dist/.build/next/server/chunks/a._.js" "$pristine/a._.js"

expect_failure 'missing compiled server' 'vanished upstream' run_patcher "$fixture/nowhere"
mkdir -p "$fixture/empty/dist/.build/next/server"
expect_failure 'no rule chunk' 'no compiled chunk carries the operator rule store' run_patcher "$fixture/empty"

# An interrupted earlier run left one chunk patched; the rerun finishes the rest.
cp -r "$fixture/pristine" "$fixture/partial"
cp "$chunks/a._.js" "$fixture/partial/dist/.build/next/server/chunks/a._.js"
assert_eq "$(run_patcher "$fixture/partial")" 'patch-operator-rules-global: OK applied (1 of 2 chunks)' 'partial tree is completed'
shared_rules "$fixture/partial/dist/.build/next/server/chunks/a._.js" "$fixture/partial/dist/.build/next/server/chunks/b._.js"

# The real anchors live only in the installed package, which the build sandbox lacks.
real="${OMNIROUTE_PKG:-$HOME/.local/share/omniroute/current/node_modules/omniroute}"
if [ -d "$real/dist/.build/next/server" ]; then
    copy="$fixture/real/dist/.build/next/server/chunks"
    mkdir -p "$copy"
    grep -rlF --include='*.js' '.reason??"quota_exhausted",scope:' "$real/dist/.build/next/server" | xargs -I{} cp {} "$copy/"
    run_patcher "$fixture/real" >/dev/null
    for f in "$copy"/*.js; do
        node --check "$f"
        assert_eq "$(grep -o '__omniroute_operatorProviderErrorRules__' "$f" | wc -l)" 1 "$(basename "$f"): shared store declared once"
        assert_eq "$(grep -o '__omniKey' "$f" | wc -l)" 2 "$(basename "$f"): setter clears in place"
    done
    printf 'installed package: %s rule chunks patch cleanly and parse\n' "$(find "$copy" -name '*.js' | wc -l)"
fi

printf 'patch-operator-rules-global tests passed\n'
