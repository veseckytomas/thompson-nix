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
# deps, and keeps the bump only if the package still builds. A rejected bump does
# not sink the surrounding update, but it exits 2 so the caller can report it.
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
plugin_dir="$repo_root/home-manager/vesecto/modules/opencode/plugins/oh-my-openagent"
target="$plugin_dir/oh-my-openagent-bun.nix"
# Shipped alongside the closure: the build copies it over upstream's lock in postPatch.
lock_target="$plugin_dir/oh-my-openagent-bun.lock"
flake_lock="$repo_root/flake.lock"
tmpdir="$(mktemp -d)"
candidate="$tmpdir/flake.lock"

# Outlives tmpdir's cleanup trap, so a rejected bump stays diagnosable after the run.
log_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nixos-run"
build_log="$log_dir/oh-my-openagent-update.log"
# Outside tmpdir too: a backup the cleanup trap deletes cannot survive a ^C mid-bump.
backup_file="$log_dir/oh-my-openagent-bun.nix.bak"
# The lock and the closure are one artifact; restoring either alone desynchronises them.
lock_backup_file="$log_dir/oh-my-openagent-bun.lock.bak"
rejected_file="$log_dir/oh-my-openagent-rejected-rev"
mkdir -p "$log_dir"

omo_url="https://github.com/code-yeongyu/oh-my-openagent"
omo_ref="dev"
locked_rev=""
# Guards against restoring a stale backup left by an earlier run.
backup_armed=0

cleanup() {
  rm -rf "$tmpdir"
}
# A signal lands between the in-place bun.nix write and the gate, where only restore heals it.
trap 'restore; cleanup; exit 130' INT TERM
trap cleanup EXIT

cd "$repo_root"

backup() {
  cp "$target" "$backup_file"
  cp "$lock_target" "$lock_backup_file"
  backup_armed=1
}

# Never fails: it runs from the signal trap and inside `if !`, where set -e would kill us.
restore() {
  if [ "$backup_armed" = 1 ] && [ -f "$backup_file" ]; then
    cp "$backup_file" "$target" || true
    cp "$lock_backup_file" "$lock_target" || true
  fi
  return 0
}

# Every step is checked explicitly: this runs inside an `if !` condition, where bash
# suspends `set -e`, so an unchecked failure would fall through to the next step.
# The candidate's rev, not the ls-remote tip: `dev` can move between the two.
read_candidate_rev() {
  locked_rev="$(jq -er '.nodes as $n | $n[$n.root.inputs["oh-my-openagent"]].locked.rev' "$candidate")" || return 1
}

# Upstream's lock resolves senpi, whose registry manifests the offline bun2nix cache lacks.
derive_bun_lock() {
  local src bun_pkg bun_bin tree

  # fetchGit at the locked rev hits the same store path the flake input already fetched.
  src="$(nix eval --raw --expr "builtins.fetchGit {
    url = \"$omo_url\";
    rev = \"$locked_rev\";
    submodules = true;
    shallow = true;
  }")" || return 1
  if [ ! -d "$src" ]; then
    printf 'oh-my-openagent: fetchGit did not yield a tree for %s\n' "${locked_rev:0:7}" >&2
    return 1
  fi

  # The build's own bun, not whatever is on PATH: a different minor writes a different lockfileVersion.
  bun_pkg="$(nix build --no-link --print-out-paths --reference-lock-file "$candidate" \
    '.#homeConfigurations.vesecto.pkgs.bun')" || return 1
  bun_bin="$bun_pkg/bin/bun"
  if [ ! -x "$bun_bin" ]; then
    printf 'oh-my-openagent: no usable bun at %s\n' "$bun_bin" >&2
    return 1
  fi

  tree="$tmpdir/tree"
  cp -a "$src" "$tree" || return 1
  chmod -R u+w "$tree" || return 1

  # The same script the build runs, so the lock basis and the build tree cannot disagree.
  python3 "$plugin_dir/strip-senpi.py" "$tree" || return 1

  # Upstream's bun.lock stays in place as the resolution basis; deleting it re-resolves every range.
  if [ ! -s "$tree/bun.lock" ]; then
    printf 'oh-my-openagent: upstream tree has no bun.lock to resolve against\n' >&2
    return 1
  fi

  if ! (cd "$tree" && "$bun_bin" install --lockfile-only); then
    printf 'oh-my-openagent: bun could not resolve the stripped tree\n' >&2
    return 1
  fi

  # A bumped lockfileVersion means bun changed format and the shipped lock would not load.
  if ! grep -qE '^\s*"lockfileVersion":\s*1\s*,?\s*$' "$tree/bun.lock"; then
    printf 'oh-my-openagent: derived bun.lock is not lockfileVersion 1\n' >&2
    grep -m1 -E '"lockfileVersion"' "$tree/bun.lock" >&2 || true
    return 1
  fi

  install -m 0644 "$tree/bun.lock" "$lock_target" || return 1
  printf 'derived bun.lock (%s bytes)\n' "$(wc -c <"$tree/bun.lock")"
}

regenerate_bun_nix() {
  local bun2nix_rev
  bun2nix_rev="$(jq -er '.nodes as $n | $n[$n.root.inputs["bun2nix"]].locked.rev' "$candidate")" || return 1

  # An ephemeral copy: the arity transform below must never reach the shipped lock.
  cp "$lock_target" "$tmpdir/bun.lock" || return 1
  if [ ! -s "$tmpdir/bun.lock" ]; then
    printf 'oh-my-openagent: derived bun.lock is empty\n' >&2
    return 1
  fi

  # bun2nix dispatches on tuple arity alone, so its github: handler is reachable only at 3.
  python3 - "$tmpdir/bun.lock" <<'PY' || return 1
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
lines = path.read_text().split("\n")

# Only "packages" holds tuples; the workspace section names github: specs as plain strings.
try:
    start = next(i for i, l in enumerate(lines) if re.match(r'\s*"packages":\s*\{', l))
except StopIteration:
    sys.exit("bun.lock has no packages section; it changed shape")

entry = re.compile(r'^\s+"(?:[^"\\]|\\.)+":\s*\["[^"]*@github:')
# Integrity is always last and always hash-prefixed, unlike the resolved-dir element.
integrity = re.compile(r',\s*"(?:sha512|sha256|sha1)-[^"]*"\s*(\],?\s*)$')

seen = stripped = 0
for i in range(start + 1, len(lines)):
    if re.match(r"^\s{2}\}", lines[i]):
        break
    if not entry.match(lines[i]):
        continue
    seen += 1
    rewritten = integrity.sub(r"\1", lines[i])
    if rewritten != lines[i]:
        lines[i] = rewritten
        stripped += 1

if seen == 0:
    sys.exit("no github: package entries; this transform is anchored to nothing")
# A no-op here means bun or bun2nix changed behaviour and the transform should go, not idle.
if stripped == 0:
    sys.exit(f"all {seen} github: entries already lack integrity; drop this transform")

path.write_text("\n".join(lines))
print(f"normalised {stripped} of {seen} github: entr(ies) for bun2nix")
PY

  if ! (cd "$tmpdir" && nix run "github:nix-community/bun2nix/$bun2nix_rev" -- -o oh-my-openagent-bun.nix); then
    printf 'bun2nix could not process the new bun.lock\n' >&2
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
  # Flake attribute evaluation must stay pure or it can silently read the live lock.
  drv="$(nix eval --raw --reference-lock-file "$candidate" '.#homeConfigurations.vesecto.config.home.packages' --apply '
    packages:
      let matches = builtins.filter (p: (p.pname or "") == "oh-my-openagent") packages;
      in if matches == [] then "" else (builtins.head matches).drvPath
  ')" || return 1
  if [ -z "$drv" ]; then
    printf 'oh-my-openagent package not found in the home configuration\n' >&2
    return 1
  fi
  # Tee'd rather than swallowed: the patch-drift message is the whole diagnostic.
  nix build --no-link --reference-lock-file "$candidate" "$drv^out" 2>&1 | tee "$build_log"
  return "${PIPESTATUS[0]}"
}

# install() unlinks before recreating; only a rename swaps the lock atomically.
promote_candidate() {
  install -m 0644 "$candidate" "$flake_lock.new" || return 1
  mv -f "$flake_lock.new" "$flake_lock" || {
    rm -f "$flake_lock.new"
    return 1
  }
}

pinned_rev="$(jq -er '.nodes as $n | $n[$n.root.inputs["oh-my-openagent"]].locked.rev' "$flake_lock")"
latest_rev="$(git ls-remote "$omo_url" "refs/heads/$omo_ref" 2>/dev/null | cut -f1 || true)"

if [ -z "$latest_rev" ]; then
  printf 'oh-my-openagent: cannot reach %s; keeping %s\n' "$omo_url" "${pinned_rev:0:7}"
  exit 0
fi

if [ "$pinned_rev" = "$latest_rev" ]; then
  printf 'oh-my-openagent: already at dev tip %s\n' "${latest_rev:0:7}"
  exit 0
fi

# Re-fetching the ~1.7 GB submodule tree to re-fail on a known-bad rev costs minutes per run.
if [ -f "$rejected_file" ] && [ "$(cat "$rejected_file")" = "$latest_rev" ]; then
  printf 'oh-my-openagent: dev tip %s still rejected; staying on %s\n' "${latest_rev:0:7}" "${pinned_rev:0:7}" >&2
  printf 'oh-my-openagent: reconcile the patches in %s, or rm %s to retry\n' "$plugin_dir" "$rejected_file" >&2
  exit 2
fi

printf 'oh-my-openagent: %s -> %s\n' "${pinned_rev:0:7}" "${latest_rev:0:7}"
backup

# Chained with && rather than a subshell: bash suspends `set -e` inside an
# `if !` condition, so a subshell there would run on past the first failure.
attempt_bump() {
  nix flake update oh-my-openagent --output-lock-file "$candidate" \
    && read_candidate_rev \
    && derive_bun_lock \
    && regenerate_bun_nix \
    && validate_build \
    && promote_candidate
}

if ! attempt_bump; then
  restore
  # locked_rev is empty when the candidate update itself failed, before any rev was resolved.
  rejected_rev="${locked_rev:-$latest_rev}"
  # Memoised against the ls-remote tip, which is what the next run compares before refetching.
  printf '%s\n' "$latest_rev" >"$rejected_file"
  printf 'oh-my-openagent: %s failed to build; staying on %s\n' "${rejected_rev:0:7}" "${pinned_rev:0:7}" >&2
  printf 'oh-my-openagent: reconcile the patches in %s\n' "$plugin_dir" >&2
  printf 'oh-my-openagent: build log kept at %s\n' "$build_log" >&2
  # nixpkgs' --replace-fail error says "doesn't match anything", never "replace-fail".
  drift_re="Hunk #.* FAILED|hunks? FAILED|patching file|can't find file|doesn't match anything|substituteInPlace.*ERROR"
  if grep -qE "$drift_re" "$build_log" 2>/dev/null; then
    printf 'oh-my-openagent: drifted anchors:\n' >&2
    grep -nE "$drift_re" "$build_log" | head -20 | sed 's/^/  /' >&2
  fi
  # Exit 2, not 0: the caller distinguishes a rejected bump from a clean run and
  # reports it after the switch, where a mid-run stderr line would scroll away.
  exit 2
fi

rm -f "$rejected_file"
printf 'Updated flake.lock, %s and %s to %s\n' "$target" "$lock_target" "${locked_rev:0:7}"
