#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / /_/ / / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
patcher="$script_dir/patch-omniroute.py"
live_source="/home/vesecto/.local/share/omniroute/omniroute@3.8.51/node_modules/omniroute/open-sse/services/learnedReasoningEffortCaps.ts"
target="open-sse/services/learnedReasoningEffortCaps.ts"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf -- "$tmp_dir"
}
trap cleanup EXIT

fail() {
  printf 'patch-omniroute-test: FAIL %s\n' "$1" >&2
  exit 1
}

assert_no_truncation_marker() {
  if grep -q '_omniroute_truncated' "$1"; then
    fail "truncation marker found in fixture"
  fi
}

run_parser_harness() {
  node --input-type=module - "$1" "$2" <<'NODE'
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const [sourcePath, mode] = process.argv.slice(2);
const source = readFileSync(sourcePath, "utf8");
const introMatch = source.match(/^const LIST_INTRO = (\/.*\/[a-z]*);/m);
const parserMatch = source.match(
  /export function parseReasoningEffortEnum\(errText: unknown\): string\[\] \| null \{\n([\s\S]*?)\n\}/
);
assert.ok(introMatch, "LIST_INTRO must remain extractable");
assert.ok(parserMatch, "parseReasoningEffortEnum body must remain extractable");

const order = ["none", "minimal", "low", "medium", "high", "xhigh", "max"];
const listIntro = Function(`"use strict"; return (${introMatch[1]});`)();
const parse = Function(
  "LIST_INTRO",
  "REASONING_EFFORT_ORDER",
  `"use strict"; return function parseReasoningEffortEnum(errText) {\n${parserMatch[1]}\n};`
)(listIntro, order);
const kimi =
  "Kimi K3 supports thinking_effort values: low, high, max (parameter=thinking_effort, value=medium)";
const expectedKimi = ["low", "high", "max"];
const accepted = parse(kimi);
console.log(`${mode}: Kimi accepted=${JSON.stringify(accepted)}`);

if (mode === "baseline") {
  assert.equal(accepted, null, "unpatched 3.8.51 unexpectedly handles Kimi wording");
} else {
  assert.deepEqual(accepted, expectedKimi, "Kimi accepted tiers must preserve low, high, max");
}
const legacyCases = [
  ["expected one of `low`, `medium`", ["low", "medium"]],
  ["Supported values are minimal, low, medium", ["minimal", "low", "medium"]],
  ["please use minimal, low, or medium", ["minimal", "low", "medium"]],
  ["expected one of `low`, `medium`, or `high`", ["low", "medium", "high"]],
  ["please use low (or medium)", ["low", "medium"]],
];
for (const [body, expected] of legacyCases) assert.deepEqual(parse(body), expected, body);
assert.equal(parse("Supported values are cat, dog"), null, "unknown tiers must not be learned");

function clampToLearned(effort, learned) {
  if (!effort || learned.has(effort)) return null;
  const rank = order.indexOf(effort);
  if (rank === -1) return null;
  const ranked = [...learned]
    .map((value) => [value, order.indexOf(value)])
    .filter(([, valueRank]) => valueRank >= 0);
  const above = ranked
    .filter(([, valueRank]) => valueRank >= rank)
    .sort(([, left], [, right]) => left - right)[0];
  return above?.[0] ?? ranked.sort(([, left], [, right]) => right - left)[0]?.[0] ?? null;
}

if (mode !== "baseline") {
  const clamped = clampToLearned("medium", new Set(accepted));
  assert.equal(clamped, "high", "medium must clamp to nearest accepted tier high");
  console.log(`clamp: medium -> ${clamped}`);
}
console.log("parser: legacy intros and no-match guard OK");
NODE
}

[ -f "$live_source" ] || fail "live 3.8.51 upstream source missing"
marker='supports (?:reasoning|thinking)_effort values?'
already_patched=0
grep -qF -- "$marker" "$live_source" && already_patched=1
fixture_root="$tmp_dir/fixture"
fixture_file="$fixture_root/$target"
mkdir -p -- "$(dirname -- "$fixture_file")"
cp -- "$live_source" "$fixture_file"
assert_no_truncation_marker "$fixture_file"

expected_first="OK applied"
if [ "$already_patched" -eq 1 ]; then
  printf 'live source already patched: skipping baseline mode\n'
  expected_first="OK already applied"
else
  run_parser_harness "$fixture_file" baseline
fi

if [ -f "$patcher" ]; then
  first_output="$(python3 "$patcher" "$fixture_root")"
  printf '%s\n' "$first_output"
  case "$first_output" in
    *"$expected_first"*) ;;
    *) fail "first patch run did not report $expected_first" ;;
  esac
else
  printf 'RED: patcher absent; exercising unpatched upstream fixture\n' >&2
fi

assert_no_truncation_marker "$fixture_file"
run_parser_harness "$fixture_file" patched
cp -- "$fixture_file" "$tmp_dir/once.ts"
second_output="$(python3 "$patcher" "$fixture_root")"
printf '%s\n' "$second_output"
case "$second_output" in
  *"OK already applied"*) ;;
  *) fail "second patch run did not report OK already applied" ;;
esac
cmp -s -- "$tmp_dir/once.ts" "$fixture_file" || fail "second patch run changed fixture bytes"
printf 'idempotency: byte-identical, already-applied OK\n'

drift_root="$tmp_dir/drift"
drift_file="$drift_root/$target"
mkdir -p -- "$(dirname -- "$drift_file")"
cp -- "$live_source" "$drift_file"
python3 - "$drift_file" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text().splitlines(keepends=True)
filtered = [line for line in lines if not line.startswith("const LIST_INTRO = ")]
if len(filtered) != len(lines) - 1:
    raise SystemExit("LIST_INTRO anchor removal was not unique")
path.write_text("".join(filtered))
PY
set +e
python3 "$patcher" "$drift_root" >"$tmp_dir/drift.out" 2>&1
drift_status=$?
set -e
[ "$drift_status" -ne 0 ] || fail "anchor drift unexpectedly succeeded"
printf 'drift: rejected missing anchor (exit %d)\n' "$drift_status"
printf 'patch-omniroute-test: PASS\n'
