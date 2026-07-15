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
# Bump pinned opencode npm-plugin versions in npm-plugins.json to npm "latest".
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
target="$repo_root/home-manager/vesecto/modules/opencode/plugins/npm-plugins.json"

tmp="$(mktemp)"
trap 'rm -f "$tmp" "$tmp.new"' EXIT
cp "$target" "$tmp"

changed=0
while IFS= read -r pkg; do
    current="$(jq -r --arg p "$pkg" '.[$p]' "$tmp")"
    latest="$(curl -fsSL "https://registry.npmjs.org/${pkg}" 2>/dev/null | jq -r '."dist-tags".latest // empty')"
    if [ -z "$latest" ]; then
        printf 'WARN: could not resolve latest for %s (keeping %s)\n' "$pkg" "$current" >&2
        continue
    fi
    if [ "$current" != "$latest" ]; then
        printf '%s: %s -> %s\n' "$pkg" "$current" "$latest"
        jq --arg p "$pkg" --arg v "$latest" '.[$p] = $v' "$tmp" >"$tmp.new"
        mv "$tmp.new" "$tmp"
        changed=1
    else
        printf '%s: %s (up to date)\n' "$pkg" "$current"
    fi
done < <(jq -r 'keys_unsorted[]' "$target")

if [ "$changed" -eq 1 ]; then
    install -m 0644 "$tmp" "$target"
    printf 'Updated %s\n' "$target"
else
    printf 'No opencode npm plugin updates.\n'
fi
