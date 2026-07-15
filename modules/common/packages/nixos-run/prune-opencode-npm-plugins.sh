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
# Prune stale opencode npm-plugin cache dirs, keeping only the npm-plugins.json version.
set -euo pipefail

: "${HOME:?HOME must be set}"

repo_root="$(git rev-parse --show-toplevel)"
pins="$repo_root/home-manager/vesecto/modules/opencode/plugins/npm-plugins.json"
pkg_dir="$HOME/.cache/opencode/packages"

if [ ! -d "$pkg_dir" ]; then
    printf 'No opencode packages cache at %s; nothing to prune.\n' "$pkg_dir"
    exit 0
fi

freed=0
pruned=0
while IFS= read -r pkg; do
    keep="$(jq -r --arg p "$pkg" '.[$p]' "$pins")"
    keep_dir="$pkg_dir/$pkg@$keep"
    for d in "$pkg_dir/$pkg" "$pkg_dir/$pkg"@*; do
        [ -e "$d" ] || continue
        [ "$d" = "$keep_dir" ] && continue
        sz="$(du -sm "$d" 2>/dev/null | cut -f1)"
        printf 'prune %s (%sM)\n' "${d#"$pkg_dir"/}" "${sz:-?}"
        rm -rf "$d"
        freed=$((freed + ${sz:-0}))
        pruned=$((pruned + 1))
    done
    if [ -d "$keep_dir" ]; then
        printf 'keep  %s@%s\n' "$pkg" "$keep"
    else
        printf 'note  %s@%s not cached yet (opencode installs it on next start)\n' "$pkg" "$keep"
    fi
done < <(jq -r 'keys_unsorted[]' "$pins")

if [ "$pruned" -eq 0 ]; then
    printf 'Nothing to prune; opencode plugin cache already minimal.\n'
else
    printf 'Pruned %d dir(s), freed ~%dM.\n' "$pruned" "$freed"
fi
