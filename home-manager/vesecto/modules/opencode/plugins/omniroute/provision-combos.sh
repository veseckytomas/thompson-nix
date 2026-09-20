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
#
# Idempotently provision OmniRoute combos from chains.json.
# For each chain: DELETE any existing combo with the same name, then POST fresh.
# Non-fatal: skips silently if OmniRoute is not running (combos persist in its SQLite DB across restarts).
set -euo pipefail

OMNIROUTE_BASE="${OMNIROUTE_BASE:-http://localhost:20128}"
OMNIROUTE_TOKEN="${OMNIROUTE_TOKEN:-}"
CHAINS_FILE="${1:?usage: provision-combos.sh <chains.json>}"

# Wait for OmniRoute to be ready (max 30s), then skip silently if still down.
ready=0
for _ in $(seq 1 30); do
  if curl -sf --max-time 2 "$OMNIROUTE_BASE/api/monitoring/health" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done
if [ "$ready" -ne 1 ]; then
  echo "omniroute-provision: OmniRoute not running at $OMNIROUTE_BASE, skipping." >&2
  exit 0
fi

auth_args=()
if [ -n "$OMNIROUTE_TOKEN" ]; then
  auth_args=(-H "Authorization: Bearer $OMNIROUTE_TOKEN")
fi

# Fetch existing combos once; response is {combos:[...]} or a bare array.
existing_raw="$(curl -sf --max-time 5 "${auth_args[@]}" "$OMNIROUTE_BASE/api/combos" 2>/dev/null || echo '[]')"

# The combos API accepts unknown model ids, so a typo only surfaces later as a
# request-time 404. Diff chain members against the live catalog and warn here.
# The `agy/` prefix is an alias; the catalog lists those under `antigravity/`.
# /v1/models is authenticated; without the token this 401s and the check self-disables.
catalog_raw="$(curl -sf --max-time 10 "${auth_args[@]}" "$OMNIROUTE_BASE/v1/models" 2>/dev/null || echo '')"
if [ -z "$catalog_raw" ]; then
  echo "omniroute-provision: WARNING - could not read the model catalog, skipping the id check." >&2
fi
if [ -n "$catalog_raw" ]; then
  missing="$(jq -r --argjson cat "$(jq -c '[.data[].id]' <<<"$catalog_raw")" '
    [ $cat[] ] as $ids
    | [ .combos[] | .name as $c | .models[] | {chain:$c, model:.} ]
    | map(select((.model | sub("^agy/";"antigravity/")) as $m | ($ids | index($m)) == null))
    | .[] | "  \(.chain): \(.model)"
  ' "$CHAINS_FILE" 2>/dev/null || true)"
  if [ -n "$missing" ]; then
    echo "omniroute-provision: WARNING - model ids absent from the live catalog:" >&2
    echo "$missing" >&2
    echo "omniroute-provision: those chain positions will 404 at request time." >&2
  fi
fi

provisioned=0
failed=0

while IFS= read -r chain; do
  name="$(jq -r '.name' <<<"$chain")"
  models_json="$(jq -c '.models' <<<"$chain")"
  strategy="$(jq -r '.strategy // "priority"' <<<"$chain")"

  # Find existing combo id by name (handles both {combos:[...]} and bare [...]).
  existing_id="$(jq -r --arg name "$name" '
    (if type == "array" then . elif .combos then .combos else [] end)
    | map(select(.name == $name))
    | .[0].id // empty
  ' <<<"$existing_raw" 2>/dev/null || true)"

  # DELETE then POST = idempotent (409-safe).
  if [ -n "$existing_id" ]; then
    curl -sf --max-time 5 -X DELETE "${auth_args[@]}" "$OMNIROUTE_BASE/api/combos/$existing_id" >/dev/null 2>&1 || true
  fi

  body="$(jq -n --arg name "$name" --argjson models "$models_json" --arg strategy "$strategy" \
    '{name: $name, models: $models, strategy: $strategy}')"

  if curl -sf --max-time 5 -X POST "${auth_args[@]}" -H "Content-Type: application/json" \
    -d "$body" "$OMNIROUTE_BASE/api/combos" >/dev/null 2>&1; then
    echo "omniroute-provision: $name ok"
    provisioned=$((provisioned + 1))
  else
    echo "omniroute-provision: $name FAILED" >&2
    failed=$((failed + 1))
  fi
done < <(jq -c '.combos[]' "$CHAINS_FILE")

echo "omniroute-provision: $provisioned provisioned, $failed failed"
