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
#
# Store the LiteLLM gateway key as x-litellm-api-key in the ctu-cc connection's providerSpecificData.customHeaders.
set -euo pipefail

OMNIROUTE_BASE="${OMNIROUTE_BASE:-http://localhost:20128}"
CONNECTION_ID="${CTU_CC_CONNECTION_ID:-cb135b3f-b057-40ff-8991-c50608c41c26}"

: "${CTU_GATEWAY_KEY:?set CTU_GATEWAY_KEY to the LiteLLM gateway API key}"

if [[ -z "${OMNIROUTE_TOKEN:-}" ]]; then
  command -v gpg-decrypt-hardened >/dev/null || {
    echo "set OMNIROUTE_TOKEN or install gpg-decrypt-hardened" >&2
    exit 1
  }
  OMNIROUTE_TOKEN="$(gpg-decrypt-hardened ~/.config/api_keys/omniroute_token.gpg | cut -d= -f2)"
fi

command -v jq >/dev/null || {
  echo "jq is required" >&2
  exit 1
}

auth_args=(-H "Authorization: Bearer $OMNIROUTE_TOKEN")

current="$(curl -fsS --max-time 15 "${auth_args[@]}" "$OMNIROUTE_BASE/api/providers/$CONNECTION_ID" | jq -e '.connection // .')"

if [[ "$(jq -r '.providerSpecificData.customHeaders["x-litellm-api-key"] // ""' <<<"$current")" == "$CTU_GATEWAY_KEY" ]]; then
  echo "ok gateway key already set"
  exit 0
fi

# providerSpecificData is replaced on update, so merge into the current object; isActive is left untouched.
http_code="$(
  jq -c --arg key "$CTU_GATEWAY_KEY" '
    (.providerSpecificData // {}) as $psd
    | {providerSpecificData: ($psd + {
        customHeaders: (($psd.customHeaders // {}) + {"x-litellm-api-key": $key})
      })}
  ' <<<"$current" |
    curl -sS --max-time 20 -o /dev/null -w '%{http_code}' -X PUT \
      "${auth_args[@]}" -H 'Content-Type: application/json' --data-binary @- \
      "$OMNIROUTE_BASE/api/providers/$CONNECTION_ID"
)"
if [[ "$http_code" != "200" && "$http_code" != "201" ]]; then
  echo "FAIL update (HTTP $http_code)" >&2
  exit 1
fi

# Management-API read-back only; no connection-test, no reactivation.
readback="$(curl -fsS --max-time 15 "${auth_args[@]}" "$OMNIROUTE_BASE/api/providers/$CONNECTION_ID" | jq -e '.connection // .')"
if [[ "$(jq -r '.providerSpecificData.customHeaders["x-litellm-api-key"] // ""' <<<"$readback")" == "$CTU_GATEWAY_KEY" ]]; then
  echo "gateway key set and verified; provider activation state unchanged"
else
  echo "VERIFY-FAIL gateway key did not persist" >&2
  exit 1
fi
