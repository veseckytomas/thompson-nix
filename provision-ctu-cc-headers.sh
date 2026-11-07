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
# Provision the Claude OAuth Authorization header on every ctu-cc model for both protocols.
set -euo pipefail

OMNIROUTE_BASE="${OMNIROUTE_BASE:-http://localhost:20128}"
PROVIDER="${CTU_CC_PROVIDER:-anthropic-compatible-cc-e968a738-66e3-43db-a12c-66be02acc136}"
CONNECTION_ID="${CTU_CC_CONNECTION_ID:-cb135b3f-b057-40ff-8991-c50608c41c26}"

: "${CLAUDE_OAUTH_TOKEN:?set CLAUDE_OAUTH_TOKEN to your Claude OAuth access token}"
CLAUDE_OAUTH_TOKEN="${CLAUDE_OAUTH_TOKEN#Bearer }"

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

authorization="Bearer $CLAUDE_OAUTH_TOKEN"
auth_args=(-H "Authorization: Bearer $OMNIROUTE_TOKEN")

# The disabled provider does not publish a live OmniRoute catalog; discover from the upstream model-list endpoint.
catalog="$(curl -fsS --max-time 15 "${auth_args[@]}" "$OMNIROUTE_BASE/api/provider-models?provider=$PROVIDER")"
connection="$(curl -fsS --max-time 15 "${auth_args[@]}" "$OMNIROUTE_BASE/api/providers/$CONNECTION_ID" | jq -e '.connection // .')"
gateway_key="$(jq -r '.providerSpecificData.customHeaders["x-litellm-api-key"] // empty' <<<"$connection")"
upstream_base="$(jq -r '.providerSpecificData.baseUrl // empty' <<<"$connection")"
: "${gateway_key:?Gateway key not configured; run set-ctu-cc-gateway-key.sh first}"
: "${upstream_base:?Connection has no providerSpecificData.baseUrl}"

upstream_live="$(curl -fsS --max-time 20 -H "x-litellm-api-key: $gateway_key" "${upstream_base%/}/v1/models")"
if ! jq -e '(.data // .models // []) | type == "array" and length > 0' <<<"$upstream_live" >/dev/null; then
  echo "Upstream returned no models; set CTU_CC_MODELS='model-a model-b ...' to provide them explicitly." >&2
  exit 1
fi

mapfile -t model_ids < <(
  {
    jq -r '.models[]? | .id // empty' <<<"$catalog"
    jq -r '(.data // .models // [])[]? | (.id // .name // empty)' <<<"$upstream_live"
    if [[ -n "${CTU_CC_MODELS:-}" ]]; then
      tr ' ' '\n' <<<"$CTU_CC_MODELS"
    fi
  } | sort -u | awk 'NF'
)
((${#model_ids[@]} > 0)) || {
  echo "No models found. Set CTU_CC_MODELS='model-a model-b ...' to pass them explicitly." >&2
  exit 1
}

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
log_file="${CTU_CC_LOG:-$HOME/.cache/ctu-cc-provision.log}"
mkdir -p "$(dirname "$log_file")"
: >"$log_file"
printf 'enumerated %s models: %s\n' "${#model_ids[@]}" "${model_ids[*]}" >>"$log_file"
failures=0

for id in "${model_ids[@]}"; do
  if current="$(jq -e --arg id "$id" '.models[]? | select(.id == $id)' <<<"$catalog" 2>/dev/null)"; then
    if [[ "$(jq -r '.upstreamHeaders.Authorization // ""' <<<"$current")" == "$authorization" ]]; then
      echo "ok   $id (already set)"
      continue
    fi
  else
    # Not a custom row yet: seed a minimal one; PUT upserts it into customModels.
    current="$(jq -nc --arg id "$id" '{id: $id, name: $id, source: "manual", apiFormat: "chat-completions", supportedEndpoints: ["chat"]}')"
  fi

  # Merge over the existing entry to preserve other headers, model metadata and compat flags.
  body_file="$tmp_dir/response.json"
  http_code="$(
    jq -c --arg provider "$PROVIDER" --arg id "$id" --arg auth "$authorization" '
      . + {
        provider: $provider,
        modelId: $id,
        upstreamHeaders: ((.upstreamHeaders // {}) + {Authorization: $auth}),
        compatByProtocol: ((.compatByProtocol // {}) + {
          openai: ((.compatByProtocol.openai // {}) + {
            upstreamHeaders: (((.compatByProtocol.openai.upstreamHeaders) // {}) + {Authorization: $auth})
          }),
          claude: ((.compatByProtocol.claude // {}) + {
            upstreamHeaders: (((.compatByProtocol.claude.upstreamHeaders) // {}) + {Authorization: $auth})
          })
        })
      }
    ' <<<"$current" |
      curl -sS --max-time 20 -o "$body_file" -w '%{http_code}' -X PUT \
        "${auth_args[@]}" -H 'Content-Type: application/json' --data-binary @- \
        "$OMNIROUTE_BASE/api/provider-models"
  )"
  if [[ "$http_code" == "200" || "$http_code" == "201" ]]; then
    echo "set  $id"
  else
    printf 'FAIL %s (HTTP %s): %s\n' "$id" "$http_code" "$(head -c 400 "$body_file" 2>/dev/null)" | tee -a "$log_file" >&2
    failures=$((failures + 1))
  fi
done

# Management-API read-back only; no inference calls or connection-test.
updated="$(curl -fsS --max-time 15 "${auth_args[@]}" "$OMNIROUTE_BASE/api/provider-models?provider=$PROVIDER")"
verified=0
for id in "${model_ids[@]}"; do
  if jq -e --arg id "$id" --arg auth "$authorization" '
    .models[] | select(.id == $id)
    | (.upstreamHeaders.Authorization == $auth)
      and (.compatByProtocol.openai.upstreamHeaders.Authorization == $auth)
      and (.compatByProtocol.claude.upstreamHeaders.Authorization == $auth)
  ' <<<"$updated" >/dev/null; then
    verified=$((verified + 1))
  else
    echo "VERIFY-FAIL $id" >&2
    failures=$((failures + 1))
  fi
done

echo "verified $verified/${#model_ids[@]} models, $failures failures"
((failures == 0))
