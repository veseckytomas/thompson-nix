#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
target_lock="$repo_root/home-manager/vesecto/modules/opencode/plugins/lockfiles/gemini-package-lock.json"
target_nix="$repo_root/home-manager/vesecto/modules/opencode/plugins/gemini.nix"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cd "$repo_root"

gemini_auth_path="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.opencode-gemini-auth.outPath')"

# Generate a fresh package-lock.json from upstream package.json
cp "$gemini_auth_path/package.json" "$tmpdir/package.json"
(
  cd "$tmpdir"
  nix shell nixpkgs#nodejs_22 -c npm install --package-lock-only
)

# Copy new lockfile
install -m 0644 "$tmpdir/package-lock.json" "$target_lock"

# Compute the npm deps hash
hash="$(nix shell nixpkgs#prefetch-npm-deps -c prefetch-npm-deps "$target_lock")"

# Update the hash in the Nix file
sed -i "s|npmDepsHash = \"sha256-[^\"]*\";|npmDepsHash = \"$hash\";|" "$target_nix"

echo "Updated flake.lock, $target_lock, and hash in $target_nix"
