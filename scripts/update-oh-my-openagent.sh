#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
plugin_dir="$repo_root/home-manager/vesecto/modules/opencode/plugins/oh-my-openagent"
target="$plugin_dir/oh-my-openagent-bun.nix"
tmpdir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cd "$repo_root"

oh_my_openagent_path="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.oh-my-openagent.outPath')"
oh_my_openagent_rev="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.oh-my-openagent.rev')"
oh_my_openagent_hash="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.oh-my-openagent.narHash')"
bun2nix_rev="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.bun2nix.rev')"

cp "$oh_my_openagent_path/bun.lock" "$tmpdir/bun.lock"

(
  cd "$tmpdir"
  nix run "github:nix-community/bun2nix/$bun2nix_rev" -- -o oh-my-openagent-bun.nix
)

python3 - "$tmpdir/oh-my-openagent-bun.nix" "$oh_my_openagent_rev" "$oh_my_openagent_hash" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
rev = sys.argv[2]
nar_hash = sys.argv[3]
text = path.read_text()

text = text.replace(
    "}:\n{\n",
    "}:\nlet\n"
    "  ohMyOpenagentSrc = fetchgit {\n"
    "    url = \"https://github.com/code-yeongyu/oh-my-openagent\";\n"
    f"    rev = \"{rev}\";\n"
    f"    hash = \"{nar_hash}\";\n"
    "    fetchSubmodules = true;\n"
    "  };\n"
    "in\n{\n",
    1,
)
text = re.sub(
    r"copyPathToStore \./packages/([^;]+);",
    r'copyPathToStore (ohMyOpenagentSrc + "/packages/\1");',
    text,
)

path.write_text(text)
PY

install -m 0644 "$tmpdir/oh-my-openagent-bun.nix" "$target"

printf 'Updated flake.lock and %s\n' "$target"
