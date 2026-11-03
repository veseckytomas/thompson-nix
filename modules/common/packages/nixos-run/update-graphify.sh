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

repo_root="$(git rev-parse --show-toplevel)"
flake_lock="$repo_root/flake.lock"
tmpdir="$(mktemp -d)"
candidate="$tmpdir/flake.lock"
log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-run"
gate_log="$log_dir/graphify-update.log"
graphify_url="https://github.com/Graphify-Labs/graphify"

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

reject_bump() {
  printf 'graphify: %s rejected; staying on %s\n' "$latest" "${current_rev:0:7}" >&2
  printf 'graphify: reconcile upstreamGraphifyAgentsMdSha256 or the uv2nix workspace\n' >&2
  printf 'graphify: gate log kept at %s\n' "$gate_log" >&2
  exit 2
}

read_locked_rev() {
  jq -er '.nodes as $n | $n[$n.root.inputs["graphify-src"]].locked.rev' "$1"
}

cd "$repo_root"
mkdir -p "$log_dir"

if ! current_rev="$(read_locked_rev "$flake_lock")"; then
  printf 'graphify: cannot read the current graphify-src revision from %s\n' "$flake_lock" >&2
  exit 2
fi

# Stay on v0.9.x because main and v1.x omit the root uv.lock required by uv2nix.
latest=$(
  git ls-remote --tags "$graphify_url" 2>/dev/null \
    | sed 's|.*refs/tags/||; s|\^{}$||' \
    | grep -E '^v0\.9\.[0-9]+$' \
    | sort -V \
    | tail -1 \
    || true
)

if [ -z "$latest" ]; then
  printf 'graphify: cannot reach %s; keeping %s\n' "$graphify_url" "${current_rev:0:7}"
  exit 0
fi

printf 'graphify: selected %s\n' "$latest"
: >"$gate_log"

if ! nix flake update graphify-src \
  --override-input graphify-src "github:Graphify-Labs/graphify/$latest" \
  --output-lock-file "$candidate" 2>&1 | tee -a "$gate_log"; then
  reject_bump
fi

if ! candidate_rev="$(read_locked_rev "$candidate")"; then
  printf 'graphify: candidate lock has no graphify-src revision\n' | tee -a "$gate_log" >&2
  reject_bump
fi

if [ "$candidate_rev" = "$current_rev" ]; then
  printf 'graphify: already at %s (%s)\n' "$latest" "${current_rev:0:7}"
  exit 0
fi

printf 'graphify: %s -> %s\n' "${current_rev:0:7}" "${candidate_rev:0:7}"

# Pure .# attributes ensure every gate reads the candidate lock rather than the live lock.
# This eval forces the lazy inlined upstream agents-md hash guard.
if ! nix eval --raw --reference-lock-file "$candidate" '.#homeConfigurations.vesecto.config.xdg.configFile."opencode/AGENTS.md".text' 2>&1 | tee -a "$gate_log"; then
  reject_bump
fi

if ! nix build --no-link --reference-lock-file "$candidate" '.#packages.x86_64-linux.graphify' 2>&1 | tee -a "$gate_log"; then
  reject_bump
fi

if ! nix build --no-link --reference-lock-file "$candidate" '.#homeConfigurations.vesecto.config.xdg.configFile."opencode/skills/graphify".source' 2>&1 | tee -a "$gate_log"; then
  reject_bump
fi

# install() unlinks before recreating; only a rename swaps the lock atomically.
if ! (install -m 0644 "$candidate" "$flake_lock.new" && mv -f "$flake_lock.new" "$flake_lock"); then
  rm -f "$flake_lock.new"
  printf 'graphify: validated %s but could not install the candidate lock\n' "$latest" >&2
  exit 2
fi

printf 'graphify: updated flake.lock to %s (%s)\n' "$latest" "${candidate_rev:0:7}"
