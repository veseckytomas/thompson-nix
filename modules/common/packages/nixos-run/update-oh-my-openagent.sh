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
# Bumps the oh-my-openagent pin to the current `dev` tip, regenerates its bun2nix
# deps, and keeps the bump only if the package still builds. A rejected bump is
# not an error: the pin is restored and the surrounding update continues.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
plugin_dir="$repo_root/home-manager/vesecto/modules/opencode/plugins/oh-my-openagent"
target="$plugin_dir/oh-my-openagent-bun.nix"
flake_nix="$repo_root/flake.nix"
flake_lock="$repo_root/flake.lock"
tmpdir="$(mktemp -d)"

omo_url="https://github.com/code-yeongyu/oh-my-openagent"
omo_ref="dev"

cleanup() {
  rm -rf "$tmpdir"
}
trap cleanup EXIT

cd "$repo_root"

backup() {
  cp "$flake_nix" "$tmpdir/flake.nix.bak"
  cp "$flake_lock" "$tmpdir/flake.lock.bak"
  cp "$target" "$tmpdir/bun.nix.bak"
}

restore() {
  cp "$tmpdir/flake.nix.bak" "$flake_nix"
  cp "$tmpdir/flake.lock.bak" "$flake_lock"
  cp "$tmpdir/bun.nix.bak" "$target"
}

read_pinned_rev() {
  python3 - "$flake_nix" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
block = re.search(r"\n    oh-my-openagent = \{(.*?)\n    \};", text, re.S)
if block is None:
    sys.exit("oh-my-openagent input block not found in flake.nix")
rev = re.search(r'rev = "([0-9a-f]{40})";', block.group(1))
if rev is None:
    sys.exit("oh-my-openagent input has no pinned rev")
print(rev.group(1))
PY
}

write_pinned_rev() {
  python3 - "$flake_nix" "$1" "$2" <<'PY'
import sys
from pathlib import Path

path, old, new = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
text = path.read_text()
if text.count(f'rev = "{old}";') != 1:
    sys.exit("expected exactly one occurrence of the pinned rev in flake.nix")
path.write_text(text.replace(f'rev = "{old}";', f'rev = "{new}";', 1))
PY
}

# Every step is checked explicitly: this runs inside an `if !` condition, where bash
# suspends `set -e`, so an unchecked failure would fall through to the next step.
regenerate_bun_nix() {
  local src_path bun2nix_rev
  src_path="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.oh-my-openagent.outPath')" || return 1
  bun2nix_rev="$(nix eval --raw --impure --expr '(builtins.getFlake (toString ./. )).inputs.bun2nix.rev')" || return 1

  cp "$src_path/bun.lock" "$tmpdir/bun.lock" || return 1
  if ! (cd "$tmpdir" && nix run "github:nix-community/bun2nix/$bun2nix_rev" -- -o oh-my-openagent-bun.nix); then
    echo "bun2nix could not process the new bun.lock" >&2
    return 1
  fi

  # Workspace members resolve against an injected `ohMyOpenagentSrc` arg (supplied by
  # the plugin's bunNix wrapper from the flake input), so no rev or hash is baked in.
  python3 - "$tmpdir/oh-my-openagent-bun.nix" <<'PY' || return 1
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

header = "  ...\n}:\n"
if header not in text:
    sys.exit("bun2nix header not found; the generated formals changed shape")
text = text.replace(header, "  ohMyOpenagentSrc,\n" + header, 1)

text, n = re.subn(
    r"copyPathToStore \./packages/([^;]+);",
    r'copyPathToStore (ohMyOpenagentSrc + "/packages/\1");',
    text,
)
if n == 0:
    sys.exit("no workspace copyPathToStore entries rewritten; bun2nix output changed shape")

path.write_text(text)
print(f"rewrote {n} workspace package paths")
PY

  install -m 0644 "$tmpdir/oh-my-openagent-bun.nix" "$target" || return 1
}

# The patch set is anchored to upstream source text and fails the build when it drifts,
# so a real build is the only trustworthy gate on a bump.
validate_build() {
  local drv
  drv="$(nix eval --raw --impure --expr '
    let
      flake = builtins.getFlake (toString ./. );
      packages = flake.homeConfigurations.vesecto.config.home.packages;
      matches = builtins.filter (p: (p.pname or "") == "oh-my-openagent") packages;
    in
      if matches == [] then "" else (builtins.head matches).drvPath
  ')"
  if [ -z "$drv" ]; then
    echo "oh-my-openagent package not found in the home configuration" >&2
    return 1
  fi
  nix build --no-link "$drv^out"
}

pinned_rev="$(read_pinned_rev)"
latest_rev="$(git ls-remote "$omo_url" "refs/heads/$omo_ref" | cut -f1)"

if [ -z "$latest_rev" ]; then
  printf 'oh-my-openagent: cannot reach %s; keeping %s\n' "$omo_url" "${pinned_rev:0:7}"
  exit 0
fi

if [ "$pinned_rev" = "$latest_rev" ]; then
  printf 'oh-my-openagent: already at dev tip %s\n' "${latest_rev:0:7}"
  exit 0
fi

printf 'oh-my-openagent: %s -> %s\n' "${pinned_rev:0:7}" "${latest_rev:0:7}"
backup

# Chained with && rather than a subshell: bash suspends `set -e` inside an
# `if !` condition, so a subshell there would run on past the first failure.
attempt_bump() {
  write_pinned_rev "$pinned_rev" "$latest_rev" \
    && nix flake update oh-my-openagent \
    && regenerate_bun_nix \
    && validate_build
}

if ! attempt_bump; then
  restore
  printf 'oh-my-openagent: %s failed to build; staying on %s\n' "${latest_rev:0:7}" "${pinned_rev:0:7}" >&2
  printf 'oh-my-openagent: rerun after reconciling the patches in %s\n' "$plugin_dir" >&2
  exit 0
fi

printf 'Updated flake.lock and %s to %s\n' "$target" "${latest_rev:0:7}"
