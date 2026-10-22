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
# budget_action must stay 'remove': with 'set' the gateway writes a thinking object that shadows target_effort.
set -euo pipefail

db="${OMNIROUTE_DB:?OMNIROUTE_DB not set}"

marker_prefix="nix:reasoning-rules:"

rules="
visual-engineering-chain max
artistry-chain max
ultrabrain-chain max
oracle-chain max
momus-chain max
deep-high-chain high
sisyphus-chain high
prometheus-chain high
metis-chain high
gsd-planner-chain high
gsd-plan-checker-chain high
gsd-reasoning-chain high
gsd-audit-chain high
didaskalos-chain high
deep-chain medium
unspecified-low-chain medium
unspecified-high-chain medium
hephaestus-chain medium
general-chain medium
atlas-chain medium
sisyphus-junior-chain medium
gsd-research-chain medium
eurybates-chain medium
mageiros-chain medium
writing-chain low
multimodal-looker-chain low
librarian-chain low
explore-chain low
reword-chain low
gsd-background-chain low
quick-chain low
"

# Every call needs the busy timeout: the gateway's PRAGMA journal_mode=WAL on each open briefly locks exclusively.
sq() {
  sqlite3 -cmd ".timeout 30000" "$db" "$@"
}

sqstr() {
  printf "'%s'" "${1//\'/\'\'}"
}

if [ ! -f "$db" ]; then
  echo "omniroute-reasoning: no database at $db (gateway not initialized yet)"
  exit 0
fi

# Exit 75 (EX_TEMPFAIL) so Restart=on-failure retries after gateway migration.
if [ "$(sq "SELECT count(*) FROM sqlite_master WHERE type='table' AND name IN ('reasoning_routing_rules','combos');")" != "2" ]; then
  echo "omniroute-reasoning: reasoning_routing_rules/combos table absent (gateway not migrated yet)" >&2
  exit 75
fi

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Nix owns every marker-prefixed row, so a rerun replaces them wholesale rather than accumulating duplicates.
sql="BEGIN; DELETE FROM reasoning_routing_rules WHERE name LIKE $(sqstr "${marker_prefix}%");"
inserted=0
skipped=0

while read -r chain effort; do
  [ -n "$chain" ] || continue

  combo_id="$(sq "SELECT id FROM combos WHERE name = $(sqstr "$chain") LIMIT 1;")"
  if [ -z "$combo_id" ]; then
    echo "omniroute-reasoning: combo '$chain' not found, skipping" >&2
    skipped=$((skipped + 1))
    continue
  fi

  marker="${marker_prefix}${chain}"
  sql="$sql INSERT INTO reasoning_routing_rules
    (id, name, description, scope, combo_id, effort_mode, target_effort, budget_action, enabled, created_at, updated_at)
    VALUES ($(sqstr "$marker"), $(sqstr "$marker"), $(sqstr "$marker"), 'combo', $(sqstr "$combo_id"),
            'force', $(sqstr "$effort"), 'remove', 1, $(sqstr "$now"), $(sqstr "$now"));"
  inserted=$((inserted + 1))
done <<EOF
$rules
EOF

sql="$sql COMMIT;"
sq "$sql" >/dev/null

total="$(sq "SELECT count(*) FROM reasoning_routing_rules WHERE name LIKE $(sqstr "${marker_prefix}%");")"
echo "omniroute-reasoning: wrote $inserted rule(s), skipped $skipped, $total owned row(s) in table"
