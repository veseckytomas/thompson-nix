#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
target="$repo_root/home-manager/vesecto/modules/opencode/plugins/lockfiles/oh-my-openagent-bun.nix"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cd "$repo_root"

oh_my_openagent_path="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.oh-my-openagent.outPath')"
bun2nix_rev="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.bun2nix.rev')"
cp "$oh_my_openagent_path/bun.lock" "$tmpdir/bun.lock"

(
  cd "$tmpdir"
  nix run "github:nix-community/bun2nix/$bun2nix_rev" -- -o oh-my-openagent-bun.nix
)

python3 - "$tmpdir/oh-my-openagent-bun.nix" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
path.write_text(path.read_text().replace("copyPathToStore ./packages/", "copyPathToStore @src@/packages/"))
PY

install -m 0644 "$tmpdir/oh-my-openagent-bun.nix" "$target"

echo "Updated flake.lock and $target"
