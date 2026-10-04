# shellcheck shell=bash
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
# nixos-run: TUI to control NixOS rebuilding.
#
# Interaction model:
#   - All user input happens UP FRONT (option selection + git pull touch)
#     or at the VERY END (nh's changes-tree confirm / commit / push / yubikey).
#   - The heavy build runs UNATTENDED, then nh shows the changes tree and asks
#     y/n before any system-changing activation; commit + push follow.

FLAKE_DIR="${NIXOS_RUN_FLAKE:-@flakePath@}"
DRY_RUN="${NIXOS_RUN_DRY_RUN:-0}"

# Build performance flags (--max-jobs / --cores), chosen per run by
# choose_performance and passed through `nh ... -- ` to nix build in the selected
# action. Empty = let Nix use its configured defaults.
PERF_FLAGS=()

# ---------------------------------------------------------------------------
# Styling helpers (gum)
# ---------------------------------------------------------------------------
hdr() { gum style --bold --foreground 212 "$@"; }
warn() { gum style --bold --foreground 196 "$@"; } # red: "Please touch the device"
info() { gum style --foreground 244 "$@"; }
ok() { gum style --bold --foreground 84 "$@"; }

# Run a state-changing command, honoring dry-run.
run() {
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] $*"
    return 0
  fi
  "$@"
}

# No-timeout confirmation gate. Returns 0 to proceed, 1 to abort.
gate() {
  echo
  if gum confirm "$1"; then
    return 0
  fi
  warn "Aborted by user."
  return 1
}

# Pause until the user presses Enter (used for physical hardware steps).
pause() {
  gum input --placeholder "$1 (press Enter)" >/dev/null 2>&1 || true
}

# A keyboxd killed without SIGTERM leaks its pubring.db dotlock, and gpg then blocks 10s on a
# dead holder and fails the signature with ETIMEDOUT -- aborting the run after activation but
# before commit + push. keyboxd.service sweeps its own leaks; this covers locks it never owned.
KEYBOX_DIR="${GNUPGHOME:-$HOME/.gnupg}/public-keys.d"

# Only a live keyboxd on THIS host makes a lock real: a recycled PID passes `kill -0` while
# owning nothing, which is the case that actually wedged signing.
keybox_lock_is_stale() {
  local file="$1" pid host comm
  [ -e "$file" ] || return 1

  pid="$(sed -n '1s/[^0-9]//gp' "$file" 2>/dev/null | head -1)"
  [ -n "$pid" ] || return 0

  host="$(sed -n '2p' "$file" 2>/dev/null)"
  [ -n "$host" ] && [ "$host" != "$(uname -n)" ] && return 0

  kill -0 "$pid" 2>/dev/null || return 0

  comm="$(cat "/proc/$pid/comm" 2>/dev/null || true)"
  [ "$comm" = "keyboxd" ] || return 0

  return 1
}

# Returns 0 only when a stale lock was actually cleared, so the caller retries just once.
clear_stale_keybox_lock() {
  local lock="$KEYBOX_DIR/pubring.db.lock"
  keybox_lock_is_stale "$lock" || return 1

  info "Stale keybox lock detected; clearing and retrying."
  # gpgconf reports "invalid pid" and still exits 0 on locks it does clear, so ignore it and
  # verify the file is gone instead.
  gpgconf --unlock pubring.db >/dev/null 2>&1 || true
  [ -e "$lock" ] && rm -f -- "$lock"
  [ -e "$lock" ] && return 1

  return 0
}

# Commit staged changes, prompting for a Yubikey touch ONLY when something is
# actually staged. Without this guard an empty `git commit` returns non-zero,
# and `set -e` (added by writeShellApplication) aborts the whole script before
# later phases run -- e.g. an empty NixOS commit would kill the run before the
# Home-Manager commit + push ever happen.
commit_if_changes() {
  if [ "$DRY_RUN" != 1 ] && git diff --cached --quiet; then
    info "Nothing to commit: $1"
    return 0
  fi
  warn "Please touch the device. (Sign commit)"
  if run git commit -m "$1"; then
    return 0
  fi

  # Retry only a stale lock: a declined touch, wrong PIN or expired key must stay fatal.
  clear_stale_keybox_lock || return 1
  warn "Please touch the device. (Sign commit, retry)"
  run git commit -m "$1"
}

# ---------------------------------------------------------------------------
# Git staging
# ---------------------------------------------------------------------------
# Files bumped only by Update; each gets its own commit and stays out of the NixOS commit.
LOCKFILES=(
  flake.lock
  home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/oh-my-openagent-bun.nix
  home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/oh-my-openagent-bun.lock
  home-manager/vesecto/modules/opencode/plugins/npm-plugins.json
  modules/common/packages/librewolf-bin.json
  home-manager/vesecto/modules/opencode/codegraph/codegraph.json
  home-manager/vesecto/modules/tock/tock.json
)

# Register untracked files in the index WITHOUT staging content: the flake evaluator skips
# files git does not know, while an intent-to-add entry stays invisible to commit_if_changes.
track_new() {
  local files=()
  mapfile -d '' -t files < <(git ls-files --others --exclude-standard -z)
  if [ "${#files[@]}" -eq 0 ]; then return 0; fi
  run git add --intent-to-add -- "${files[@]}"
}

# Restore only the lockfiles git already knows: `git restore --staged` errors out on a path
# absent from both index and HEAD, which would abort the run on a never-committed lockfile.
unstage_lockfiles() {
  local known=()
  mapfile -d '' -t known < <(git ls-files -z -- "${LOCKFILES[@]}")
  if [ "${#known[@]}" -eq 0 ]; then return 0; fi
  run git restore --staged -- "${known[@]}"
}

# Stage everything (incl. new/untracked files) so the flake evaluator sees them before a build/switch.
stage_all() { run git add --all; }

# A bare restore drops new files back to untracked, which re-breaks the evaluator mid-run.
unstage_all() {
  run git restore --staged :/
  track_new
}

# Stage the NixOS commit: everything except the home-manager dir and the update-only lockfiles.
stage_nixos() {
  unstage_all
  run git add --all
  run git restore --staged home-manager
  unstage_lockfiles
  track_new
}

# Stage the Home-Manager commit: the home-manager dir only.
stage_home() {
  unstage_all
  run git add home-manager
  track_new
}

# Stage the Update commit: the update-only lockfiles only.
# Only the ones present on disk: `git add` aborts the run on a lockfile a failed
# generator never wrote, which would strand the repo half-staged mid-Update.
stage_lockfiles() {
  local present=()
  local f
  for f in "${LOCKFILES[@]}"; do
    if [ -e "$f" ]; then present+=("$f"); fi
  done
  unstage_all
  if [ "${#present[@]}" -gt 0 ]; then run git add -- "${present[@]}"; fi
  track_new
}

print_help() {
  cat <<EOF
nixos-run - TUI to control NixOS rebuilding

Usage: nixos-run [--dry-run|-n] [--help|-h]

All interactive input happens up front (build performance + option selection) or
at the very end (switch / commit / push / yubikey). The build runs unattended in
between, with a no-timeout confirmation gate before any system-changing
activation.

Rebuild actions first ask for a build performance profile:
  Light  --max-jobs 1 --cores 1     (one job, one core; keeps the PC usable)
  Full   --max-jobs auto --cores 0  (all jobs, all cores; finishes ASAP)

Interactive controls:
  ↑/↓ or h/j/k/l  Navigate lists
  space            Toggle selected item
  a                Select/unselect all (multi-select lists)
  enter            Confirm selection

Environment:
  NIXOS_RUN_FLAKE     Path to the flake repo (default: @flakePath@)
  NIXOS_RUN_DRY_RUN   Set to 1 to print state-changing commands instead of
                      running them.
EOF
}

# ---------------------------------------------------------------------------
# Shared phases
# ---------------------------------------------------------------------------

# Early step (user is still present): pull latest. May require a Yubikey touch
# for the SSH remote, hence it lives in the up-front phase.
git_pull() {
  warn "Please touch the device. (Pull)"
  run git pull || warn "git pull failed, continuing."
}

# Up-front step: pick how much CPU the unattended build may use. Sets the global
# PERF_FLAGS array, passed through nh to nix build + switch in the chosen action.
#   - Light: one job, one core   -> machine stays responsive during the build.
#   - Full:  all jobs, all cores -> build finishes as fast as possible.
# A cancelled prompt defaults to Light (the safe, non-hogging choice).
choose_performance() {
  local choice
  choice=$(gum choose --header "Build performance (CPU usage for this run):" \
    "Light - keep PC usable (1 job, 1 core)" \
    "Full - finish ASAP (unlimited jobs, unlimited cores)" || true)
  case "$choice" in
  "Full"*) PERF_FLAGS=(--max-jobs auto --cores 0) ;;
  *) PERF_FLAGS=(--max-jobs 1 --cores 1) ;;
  esac
  info "Build performance: ${PERF_FLAGS[*]}"
}

# Cache sudo up front so nh's activation escalation doesn't stall mid-build.
cache_sudo() {
  warn "Caching sudo credentials (may need password/touch) ..."
  run sudo -v || warn "sudo cache failed; nh may prompt during activation."
}

# nh --ask is the gate: build -> changes tree -> y/n -> activate, atomically.
nh_os() {
  hdr "NixOS ($(hostname)): build + changes tree + confirm + activate ..."
  run nh os "$1" --hostname "$(hostname)" --ask --diff always -- "${PERF_FLAGS[@]}"
}

nh_home() {
  hdr "Home-Manager ($(whoami)): build + changes tree + confirm + activate ..."
  run nh home switch --configuration "$(whoami)" --ask --diff always -- "${PERF_FLAGS[@]}"
}

current_nixos_gen() {
  nixos-rebuild list-generations | grep True | cut -d' ' -f1 || true
}

current_home_gen() {
  home-manager generations | head -1 | cut -d' ' -f5 || true
}

# ---------------------------------------------------------------------------
# Action: Rebuild (NixOS + Home-Manager)
# ---------------------------------------------------------------------------
action_rebuild() {
  choose_performance
  cache_sudo
  git_pull

  stage_all

  # Non-zero (decline or failure) = nothing activated: unstage, don't commit.
  if ! nh_os switch; then
    warn "NixOS switch not completed; nothing committed."
    unstage_all
    return 1
  fi
  local gen
  gen=$(current_nixos_gen)
  stage_nixos
  commit_if_changes "$(hostname): Gen ${gen}"

  stage_all
  if ! nh_home; then
    warn "Home-Manager switch not completed; nothing committed."
    unstage_all
    return 1
  fi
  local hgen
  hgen=$(current_home_gen)
  stage_home
  commit_if_changes "Home-manager $(hostname): Gen ${hgen}"

  warn "Please touch the device. (Push)"
  run git push
  ok "Rebuild complete."
}

# ---------------------------------------------------------------------------
# Action: Home-Manager only
# ---------------------------------------------------------------------------
action_home() {
  choose_performance
  git_pull

  stage_all
  if ! nh_home; then
    warn "Home-Manager switch not completed; nothing committed."
    unstage_all
    return 1
  fi
  local hgen
  hgen=$(current_home_gen)
  stage_home
  commit_if_changes "Home-manager $(hostname): Gen ${hgen}"
  warn "Please touch the device. (Push)"
  run git push
  ok "Home-Manager rebuild complete."
}

# ---------------------------------------------------------------------------
# Action: Rebuild Test (build, then activate test config; no commit)
# ---------------------------------------------------------------------------
action_test() {
  choose_performance
  cache_sudo
  git_pull

  stage_all
  nh_os test || warn "Test activation not completed."
  unstage_all
  ok "Test complete (not persisted across reboot)."
}

# ---------------------------------------------------------------------------
# Action: Update (flake + plugins + librewolf, then rebuild NixOS + Home)
# ---------------------------------------------------------------------------
update_librewolf() {
  local json="modules/common/packages/librewolf-bin.json"
  local latest current sum hash
  latest=$(curl -H 'accept: application/json' -sL https://codeberg.org/api/v1/repos/librewolf/bsys6/releases/latest | jq -r '.tag_name' || true)
  current=$(jq -r '.version' "$json" 2>/dev/null || true)
  if [ -z "$latest" ] || [ "$latest" = "null" ]; then
    warn "LibreWolf: could not fetch latest version, keeping ${current}."
  elif [ "$latest" = "$current" ]; then
    info "LibreWolf: already up-to-date (${current})"
  else
    sum=$(curl -sfL "https://codeberg.org/api/packages/librewolf/generic/librewolf/$latest/librewolf-$latest-linux-x86_64-package.tar.xz.sha256sum" | awk '{print $1}' || true)
    if [ -z "$sum" ]; then
      warn "LibreWolf: could not fetch checksum for ${latest}, keeping ${current}."
    else
      hash=$(nix --extra-experimental-features 'nix-command' hash convert --to sri --hash-algo sha256 "$sum")
      if [ "$DRY_RUN" = 1 ]; then
        info "[dry-run] would write ${json}: ${latest} / ${hash}"
      else
        printf '{\n  "version": "%s",\n  "hash": "%s"\n}\n' "$latest" "$hash" >"$json"
      fi
      info "LibreWolf: ${current} -> ${latest}"
    fi
  fi
}

# CodeGraph ships as a platform-specific npm bundle that runs under nixpkgs Node
# (see home-manager/vesecto/modules/opencode/codegraph). npm's per-version
# dist.integrity is already an SRI hash, so we read it straight from the registry
# packument -- no tarball download needed to bump version + hash.
update_codegraph() {
  local json="home-manager/vesecto/modules/opencode/codegraph/codegraph.json"
  local pkg="@colbymchenry/codegraph-linux-x64"
  local packument latest current hash
  packument=$(curl -H 'accept: application/json' -sL "https://registry.npmjs.org/${pkg}" || true)
  latest=$(jq -r '."dist-tags".latest' <<<"$packument" 2>/dev/null || true)
  current=$(jq -r '.version' "$json" 2>/dev/null || true)
  if [ -z "$latest" ] || [ "$latest" = "null" ]; then
    warn "CodeGraph: could not fetch latest version, keeping ${current}."
  elif [ "$latest" = "$current" ]; then
    info "CodeGraph: already up-to-date (${current})"
  else
    hash=$(jq -r --arg v "$latest" '.versions[$v].dist.integrity' <<<"$packument" 2>/dev/null || true)
    if [ -z "$hash" ] || [ "$hash" = "null" ]; then
      warn "CodeGraph: could not fetch integrity for ${latest}, keeping ${current}."
    else
      if [ "$DRY_RUN" = 1 ]; then
        info "[dry-run] would write ${json}: ${latest} / ${hash}"
      else
        printf '{\n  "version": "%s",\n  "hash": "%s"\n}\n' "$latest" "$hash" >"$json"
      fi
      info "CodeGraph: ${current} -> ${latest}"
    fi
  fi
}

# tock's source is pinned by flake.lock, but its Go dep hash cannot be: vendorHash
# lives in ./tock.json. Recompute it only when the locked rev moved, by building
# the goModules FOD against a fake hash and reading the real one off the mismatch.
update_tock() {
  local json="home-manager/vesecto/modules/tock/tock.json"
  local locked pinned hash out
  locked=$(jq -r '.nodes.tock.locked.rev' flake.lock 2>/dev/null || true)
  pinned=$(jq -r '.rev' "$json" 2>/dev/null || true)
  if [ -z "$locked" ] || [ "$locked" = "null" ]; then
    warn "tock: no tock input in flake.lock, keeping ${pinned:0:7}."
    return 0
  fi
  if [ "$locked" = "$pinned" ]; then
    info "tock: vendorHash already up-to-date (${pinned:0:7})"
    return 0
  fi
  # Probe a bare buildGoModule instead of package.nix: the latter reads tock.json, so
  # using it here would deadlock whenever that file is missing or holds a stale hash.
  out=$(nix --extra-experimental-features 'nix-command flakes' build --impure --no-link --expr "
    let f = builtins.getFlake \"$PWD\";
        p = f.inputs.nixpkgs.legacyPackages.x86_64-linux;
    in (p.buildGoModule {
      pname = \"tock\";
      version = \"probe\";
      src = f.inputs.tock;
      vendorHash = p.lib.fakeHash;
      subPackages = [\"cmd/tock\"];
    }).goModules" 2>&1 || true)
  hash=$(sed -n 's/.*got: *\(sha256-[A-Za-z0-9+/=]*\).*/\1/p' <<<"$out" | head -1)
  if [ -z "$hash" ]; then
    # With no tock.json to fall back on there is nothing to keep, and every later phase
    # that evaluates the flake would fail on the missing import.
    if [ ! -e "$json" ]; then
      warn "tock: could not compute vendorHash for ${locked:0:7} and ${json} is missing."
      printf '%s\n' "$out" | tail -20
      return 1
    fi
    warn "tock: could not compute vendorHash for ${locked:0:7}, keeping ${pinned:0:7}."
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would write ${json}: ${locked:0:7} / ${hash}"
  else
    printf '{\n  "rev": "%s",\n  "vendorHash": "%s"\n}\n' "$locked" "$hash" >"$json"
  fi
  info "tock: ${pinned:0:7} -> ${locked:0:7}"
}

action_update() {
  choose_performance
  cache_sudo
  git_pull

  track_new

  hdr "Updating flake inputs ..."
  local bulk=()
  # The two gated inputs move only behind their own build gates.
  mapfile -t bulk < <(nix flake metadata --json --no-write-lock-file . \
    | jq -er '.locks as $l | $l.nodes[$l.root].inputs | keys[]
              | select(. != "oh-my-openagent" and . != "graphify-src")')
  if [ "${#bulk[@]}" -eq 0 ]; then
    warn "Flake inputs: could not compute update allowlist; skipping bulk update."
  else
    run nix flake update "${bulk[@]}"
  fi
  hdr "Updating oh-my-openagent ..."
  # A rejected upstream bump must not sink the rest of the update, but exit 2 is a
  # drifted patch set and is re-reported after the switch, where it cannot scroll away.
  local omo_rejected=0
  run bash "@updateOhMyOpenagentScript@" || omo_rejected=$?
  hdr "Updating graphify ..."
  local graphify_rejected=0
  run bash "@updateGraphifyScript@" || graphify_rejected=$?
  hdr "Updating opencode npm plugins ..."
  run bash "@updateOpencodeNpmPluginsScript@"
  hdr "Updating LibreWolf ..."
  update_librewolf
  hdr "Updating CodeGraph ..."
  update_codegraph
  hdr "Updating tock ..."
  update_tock

  stage_all
  if ! nh_os switch; then
    warn "NixOS switch not completed; nothing committed."
    unstage_all
    return 1
  fi
  # Commit lockfiles first (matches scripts/update.sh), only after activation.
  stage_lockfiles
  commit_if_changes "Update lockfiles"
  local gen
  gen=$(current_nixos_gen)
  stage_nixos
  commit_if_changes "$(hostname): Gen ${gen}"

  stage_all
  if ! nh_home; then
    warn "Home-Manager switch not completed; nothing committed."
    unstage_all
    return 1
  fi
  local hgen
  hgen=$(current_home_gen)
  stage_home
  commit_if_changes "Home-manager $(hostname): Gen ${hgen}"

  warn "Please touch the device. (Push)"
  run git push

  local unchanged=()
  if [ "$omo_rejected" -ne 0 ]; then
    warn "oh-my-openagent: STILL ON THE OLD PIN - patch set drifted."
    warn "  Reconcile: home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/"
    warn "  Build log: ${XDG_STATE_HOME:-$HOME/.local/state}/nixos-run/oh-my-openagent-update.log"
    unchanged+=("oh-my-openagent")
  fi
  if [ "$graphify_rejected" -ne 0 ]; then
    warn "graphify: STILL ON THE OLD PIN - gate failed."
    warn "  Reconcile: home-manager/vesecto/modules/opencode/default.nix (upstreamGraphifyAgentsMdSha256) or uv2nix workspace layout"
    warn "  Build log: ${XDG_STATE_HOME:-$HOME/.local/state}/nixos-run/graphify-update.log"
    unchanged+=("graphify")
  fi
  if [ "${#unchanged[@]}" -gt 0 ]; then
    ok "Update complete (${unchanged[*]} pin(s) unchanged)."
  else
    ok "Update complete."
  fi
}

# ---------------------------------------------------------------------------
# Action: Garbage collect (options chosen up front; sudo cached once)
# ---------------------------------------------------------------------------
action_clean() {
  local choices
  choices=$(gum choose --no-limit \
    --header "Select cleanup tasks (hjkl to navigate, space to toggle, a to select/unselect all, enter to confirm):" \
    "Clean boot partition (>14d)" \
    "Clean Pip cache" \
    "Clean dev shells (.direnv)" \
    "Clean nix-store (gc + optimize)" \
    "Prune Nix fetcher cache (git/tarball)" \
    "Prune opencode plugin cache (stale versions)" \
    "Prune docker cache" \
    "Empty trash" || true)

  if [ -z "$choices" ]; then
    info "Nothing selected."
    return 0
  fi

  # Cache sudo credentials up front if any privileged task was selected.
  if grep -qF "boot partition" <<<"$choices" || grep -qF "nix-store" <<<"$choices"; then
    warn "Caching sudo credentials ..."
    run sudo -v
  fi

  if grep -qF "boot partition" <<<"$choices"; then
    hdr "Cleaning boot partition ..."
    run sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 14d || warn "Boot partition cleanup failed."
  fi
  if grep -qF "Pip cache" <<<"$choices"; then
    hdr "Cleaning Pip cache ..."
    run nix run nixpkgs#python3Packages.pip cache purge || warn "Pip cache cleanup failed."
  fi
  if grep -qF "dev shells" <<<"$choices"; then
    hdr "Cleaning dev shells (.direnv) ..."
    run fd -HI '^\.direnv$' "$HOME" -E .git -E Trash -X rm -r || warn "Dev shell cleanup failed."
  fi
  if grep -qF "nix-store" <<<"$choices"; then
    hdr "Cleaning nix-store ..."
    run rm -rf "$HOME/.local/share/nvim/mason" || true
    run sudo nix-collect-garbage -d || warn "System garbage collection failed."
    run sudo /run/current-system/bin/switch-to-configuration boot || warn "switch-to-configuration boot failed."
    run nix-collect-garbage -d || warn "User garbage collection failed."
    run nix-store --optimize || warn "Store optimization failed."
  fi
  if grep -qF "Nix fetcher cache" <<<"$choices"; then
    # These caches live OUTSIDE the nix store, so `nix-collect-garbage` never
    # touches them. The git mirror (gitv3) keeps full per-input clones —
    # including submodules like oh-my-openagent's ~1.7 GB open-design — and the
    # tarball caches keep every github: input snapshot. Nix re-fetches lazily on
    # the next build, so removing them is always safe.
    hdr "Pruning Nix fetcher cache (git mirrors + tarball downloads) ..."
    run rm -rf "$HOME/.cache/nix/gitv3" "$HOME/.cache/nix/tarball-cache" "$HOME/.cache/nix/tarball-cache-v2" || warn "Nix fetcher cache prune failed."
  fi
  if grep -qF "opencode plugin cache" <<<"$choices"; then
    hdr "Pruning opencode plugin cache (stale plugin versions) ..."
    run bash "@pruneOpencodeNpmPluginsScript@" || warn "opencode plugin cache prune failed."
  fi
  if grep -qF "docker cache" <<<"$choices"; then
    hdr "Pruning docker cache ..."
    run docker system prune -af --volumes || warn "Docker prune failed."
  fi
  if grep -qF "Empty trash" <<<"$choices"; then
    hdr "Emptying trash ..."
    run trash-empty -f --all-users || warn "Empty trash failed."
  fi
  ok "Cleanup complete."
}

# ---------------------------------------------------------------------------
# Action: Generate ISO
# ---------------------------------------------------------------------------
action_iso() {
  local choices
  choices=$(gum choose --no-limit --header "Select ISOs to build:" \
    "Rescue ISO" "Install ISO" || true)
  if [ -z "$choices" ]; then
    info "Nothing selected."
    return 0
  fi

  git_pull
  stage_all
  run mkdir -p build

  if grep -qF "Rescue ISO" <<<"$choices"; then
    hdr "Building rescue ISO ..."
    run nix run nixpkgs#nixos-generators -- --format iso --flake ".#rescueIso" -o build/rescue || warn "Rescue ISO build failed."
  fi
  if grep -qF "Install ISO" <<<"$choices"; then
    hdr "Building install ISO ..."
    run nix run nixpkgs#nixos-generators -- --format iso --flake ".#installIso" -o build/install || warn "Install ISO build failed."
  fi

  unstage_all
  ok "ISO generation complete."
}

# ---------------------------------------------------------------------------
# Action: Setup (bootstrap). Yubikey config moved to the end batch.
# ---------------------------------------------------------------------------
setup_yubikeys() {
  if [ -f "$HOME/.config/Yubico/u2f_keys" ]; then
    info "Yubikeys already configured."
    return 0
  fi
  run mkdir -p "$HOME/.config/Yubico"
  warn "Insert FIRST Yubikey."
  pause "First Yubikey inserted?"
  run nix-shell -p pam_u2f --run "pamu2fcfg > \"$HOME/.config/Yubico/u2f_keys\""
  warn "Insert SECOND Yubikey."
  pause "Second Yubikey inserted?"
  run nix-shell -p pam_u2f --run "pamu2fcfg -n >> \"$HOME/.config/Yubico/u2f_keys\""
  ok "Yubikeys configured."
}

setup_clone() {
  hdr "Cloning repositories ..."
  run git clone git@gitlab.com:vesecky.tomas/thompson-nix.git "$HOME/Git/Personal/thompson-nix" || warn "Clone thompson-nix failed."
  run git clone git@gitlab.com:vesecky.tomas/thompson-obsidian.git "$HOME/Git/Personal/thompson-obsidian" || warn "Clone thompson-obsidian failed."
  run git clone git@gitlab.com:homelab1960731/thompson-dwh.git "$HOME/DataGripProjects/Homelab" || warn "Clone thompson-dwh failed."
  run git clone git@gitlab.fit.cvut.cz:vesecto1/dwh-project.git "$HOME/DataGripProjects/DWH" || warn "Clone dwh-project failed."
}

setup_eduroam() {
  hdr "Installing eduroam ..."
  if [ "$DRY_RUN" = 1 ]; then
    info "[dry-run] would download and run eduroam installer"
    return 0
  fi
  curl "https://cat.eduroam.org/user/API.php?action=downloadInstaller&lang=en&profile=2904&device=linux&generatedfor=user&openroaming=0" >eduroam.py
  nix-shell -p 'python311.withPackages(ps: with ps; [ dbus-python ])' --run "python3 ./eduroam.py" || warn "eduroam installer failed."
  rm -f eduroam.py
}

action_setup() {
  local hostname_in opts yubi clone eduroam
  hostname_in=$(gum input --header "Enter hostname:" --placeholder "TomasVesa-PC-NixOS" || true)
  if [ -z "$hostname_in" ]; then
    warn "Hostname is required."
    return 1
  fi
  opts=$(gum choose --no-limit --header "Setup options:" \
    "Install Yubikeys" "Clone repositories" "Install eduroam" || true)
  if grep -qF "Install Yubikeys" <<<"$opts"; then yubi=yes; else yubi=no; fi
  if grep -qF "Clone repositories" <<<"$opts"; then clone=yes; else clone=no; fi
  if grep -qF "Install eduroam" <<<"$opts"; then eduroam=yes; else eduroam=no; fi

  git_pull
  track_new

  # --- unattended build ---
  hdr "Building NixOS configuration (.#${hostname_in}) ..."
  run nixos-rebuild build --flake ".#${hostname_in}"

  if ! gate "Build complete. Proceed to activate (boot) + home-manager + extras?"; then
    return 0
  fi

  # --- attended end ---
  warn "Setting boot configuration (sudo) ..."
  run sudo nixos-rebuild boot -j 8 --cores 8 --flake ".#${hostname_in}"
  warn "Activating Home-Manager ..."
  run nix-shell -p home-manager --run "home-manager switch --flake .#$(whoami)"

  if [ "$yubi" = yes ]; then setup_yubikeys; fi
  if [ "$clone" = yes ]; then setup_clone; fi
  if [ "$eduroam" = yes ]; then setup_eduroam; fi

  if command -v protonup >/dev/null 2>&1; then
    hdr "Running protonup ..."
    run protonup
  fi
  ok "Setup complete."
}

# ---------------------------------------------------------------------------
# Main menu
# ---------------------------------------------------------------------------
main_menu() {
  hdr "NixOS Rebuild Control"
  if [ "$DRY_RUN" = 1 ]; then
    info "(dry-run: state-changing commands are printed, not executed)"
  fi

  local action
  action=$(gum choose --header "Choose an action:" \
    "Rebuild (NixOS + Home-Manager)" \
    "Home-Manager only" \
    "Rebuild Test" \
    "Update (flake + plugins, then rebuild)" \
    "Garbage collect" \
    "Generate ISO" \
    "Setup (bootstrap)" \
    "Exit" || true)

  case "$action" in
  "Rebuild (NixOS + Home-Manager)") action_rebuild ;;
  "Home-Manager only") action_home ;;
  "Rebuild Test") action_test ;;
  "Update (flake + plugins, then rebuild)") action_update ;;
  "Garbage collect") action_clean ;;
  "Generate ISO") action_iso ;;
  "Setup (bootstrap)") action_setup ;;
  "Exit" | "")
    info "Exiting ..."
    exit 0
    ;;
  *)
    warn "Unknown action."
    exit 1
    ;;
  esac
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
while [ "$#" -gt 0 ]; do
  case "$1" in
  -n | --dry-run)
    DRY_RUN=1
    shift
    ;;
  -h | --help)
    print_help
    exit 0
    ;;
  *)
    warn "Unknown argument: $1"
    print_help
    exit 1
    ;;
  esac
done

if [ ! -d "$FLAKE_DIR" ]; then
  warn "Flake directory not found: ${FLAKE_DIR}"
  info "Set NIXOS_RUN_FLAKE to override the default."
  exit 1
fi
cd "$FLAKE_DIR"

main_menu
