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
set -euo pipefail

source_script="$(dirname "$0")/nixos-run.sh"
bash_bin="$(command -v bash)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin"
transcript="$fixture/transcript"
export NIXOS_RUN_TEST_TRANSCRIPT="$transcript"

{
  printf '#!%s\n' "$bash_bin"
  sed \
    -e "s|@flakePath@|$fixture|g" \
    -e 's|@updateOhMyOpenagentScript@|/bin/true|g' \
    -e 's|@updateGraphifyScript@|/bin/true|g' \
    -e 's|@updateOpencodeNpmPluginsScript@|/bin/true|g' \
    -e 's|@pruneOpencodeNpmPluginsScript@|/bin/true|g' \
    -e 's|@verifyOmnirouteResilienceReadersScript@|/bin/true|g' \
    "$source_script"
} >"$fixture/nixos-run"
chmod +x "$fixture/nixos-run"

printf '#!%s\n' "$bash_bin" >"$fixture/bin/gum"
cat >>"$fixture/bin/gum" <<'EOF'
set -euo pipefail
printf 'gum %s\n' "$*" >>"$NIXOS_RUN_TEST_TRANSCRIPT"
if [ "${1:-}" != choose ]; then exit 0; fi
if [[ "$*" == *"Build performance (CPU usage for this run):"* ]]; then
  [ -n "${NIXOS_RUN_PERF_CHOICE:-}" ] || exit 1
  printf '%s\n' "$NIXOS_RUN_PERF_CHOICE"
else
  printf 'Rebuild Test\n'
fi
EOF

printf '#!%s\n' "$bash_bin" >"$fixture/bin/stub"
cat >>"$fixture/bin/stub" <<'EOF'
set -euo pipefail
name="${0##*/}"
printf '%s %s\n' "$name" "$*" >>"$NIXOS_RUN_TEST_TRANSCRIPT"
case "$name" in
hostname) printf 'test-host\n' ;;
whoami) printf 'test-user\n' ;;
git) [ "${1:-}" = status ] && printf ' M fixture\n' ;;
esac
EOF
chmod +x "$fixture/bin/gum" "$fixture/bin/stub"
ln -s "$bash_bin" "$fixture/bin/bash"
for command in nh git hostname whoami sudo nix uname; do ln -s stub "$fixture/bin/$command"; done

failures=0
run_scenario() {
  local id="$1" choice="$2" expected="$3"
  : >"$transcript"
  NIXOS_RUN_PERF_CHOICE="$choice" NIXOS_RUN_DRY_RUN=1 PATH="$fixture/bin:/bin:/usr/bin" \
    "$bash_bin" "$fixture/nixos-run" >/dev/null
  if grep -qF "nh os test --hostname test-host --ask --diff always -- $expected" "$transcript"; then
    printf '%s PASS: %s\n' "$id" "$expected"
  else
    printf '%s FAIL: expected nh argv ending -- %s\n' "$id" "$expected"
    failures=$((failures + 1))
  fi
}

run_scenario S1 Balanced '--max-jobs 2 --cores 4'
run_scenario S2 '' '--max-jobs 2 --cores 4'
run_scenario S3 Light '--max-jobs 1 --cores 1'
run_scenario S4 Full '--max-jobs auto --cores 0'
run_scenario S5 Full '--max-jobs auto --cores 0'

if [ "$failures" -ne 0 ]; then
  printf 'choose-performance: FAIL (%d scenario(s))\n' "$failures"
  exit 1
fi
printf 'choose-performance: PASS\n'
