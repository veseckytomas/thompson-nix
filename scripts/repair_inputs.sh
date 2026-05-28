#!/usr/bin/env bash
#   _______
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas

# Repair Nix git inputs cache when git aggressively packs refs,
# causing "utimensat: No such file or directory" errors during `nix flake update`.

set -euo pipefail

fixed=0

for dir in ~/.cache/nix/gitv3/*/; do
  [ -f "$dir/packed-refs" ] || continue

  while IFS= read -r line; do
    [[ "$line" =~ ^# ]] && continue

    hash="${line%% *}"
    ref="${line#* }"
    loose="$dir/$ref"

    [ -f "$loose" ] && continue

    mkdir -p "$(dirname "$loose")"
    echo "$hash" > "$loose"
    echo "Unpacked $ref in $(basename "$dir")"
    ((fixed++)) || true
  done < "$dir/packed-refs"
done

if [ "$fixed" -eq 0 ]; then
  echo "No packed refs needed unpacking."
else
  echo "Fixed $fixed missing loose ref(s)."
fi
