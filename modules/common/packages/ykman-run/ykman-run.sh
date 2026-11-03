# shellcheck shell=bash
#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
# ykman-run: TUI to manage YubiKey OpenPGP touch policies (auth / sign / decrypt).

DRY_RUN="${YKMAN_RUN_DRY_RUN:-0}"

# Applied to every ykman call; set to (--device SERIAL) only when >1 key present.
YK_DEV=()

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

print_help() {
  cat <<EOF
ykman-run - TUI to manage YubiKey OpenPGP touch policies

Usage: ykman-run [--dry-run|-n] [--help|-h]

Sets the OpenPGP touch policy (on/off) for the authentication, signing and
decryption keys via ykman. You pick the device, keys and policy and confirm;
ykman then prompts for the OpenPGP admin PIN as each selected key is changed.

Interactive controls:
  ↑/↓ or h/j/k/l  Navigate lists
  space            Toggle selected item
  a                Select/unselect all (multi-select lists)
  enter            Confirm selection

Environment:
  YKMAN_RUN_DRY_RUN  Set to 1 to print set-touch commands instead of running
                     them.
EOF
}

# ---------------------------------------------------------------------------
# Device + status helpers
# ---------------------------------------------------------------------------

# Populate YK_DEV: 0 keys -> abort, 1 -> no selector, >1 -> pick a serial.
choose_device() {
  local serials
  mapfile -t serials < <(ykman list --serials 2>/dev/null || true)
  case "${#serials[@]}" in
  0)
    warn "No YubiKey detected. Insert a key and try again."
    return 1
    ;;
  1) YK_DEV=() ;;
  *)
    local pick
    pick=$(printf '%s\n' "${serials[@]}" | gum choose --header "Multiple YubiKeys detected — choose by serial:" || true)
    if [ -z "$pick" ]; then
      warn "No device selected."
      return 1
    fi
    YK_DEV=(--device "$pick")
    ;;
  esac
}

# Extract the Touch policy value for one key block from `ykman openpgp info`.
policy_from_info() {
  awk -v h="$2" 'index($0, h) == 1 {f = 1; next} f && /Touch policy:/ {print $3; exit}' <<<"$1"
}

print_status() {
  local out aut sig dec
  if ! out=$(ykman "${YK_DEV[@]}" openpgp info 2>/dev/null); then
    warn "Could not read YubiKey OpenPGP status (is a key inserted?)."
    return 1
  fi
  aut=$(policy_from_info "$out" "Authentication key:")
  sig=$(policy_from_info "$out" "Signature key:")
  dec=$(policy_from_info "$out" "Decryption key:")
  hdr "Current OpenPGP touch policies:"
  info "  Authentication : ${aut:-unknown}"
  info "  Signing        : ${sig:-unknown}"
  info "  Decryption     : ${dec:-unknown}"
}

# ---------------------------------------------------------------------------
# Action: Set touch policy
# ---------------------------------------------------------------------------

# ykman prompts for the admin PIN itself (per call), so it never touches argv.
apply_touch() {
  local slot="$1" policy="$2" label="$3"
  if run ykman "${YK_DEV[@]}" openpgp keys set-touch -f "$slot" "$policy"; then
    ok "${label} touch policy set to '${policy}'."
    return 0
  fi
  warn "${label}: set-touch failed (wrong admin PIN, or a fixed policy is already set)."
  return 1
}

action_set() {
  choose_device || return 0
  print_status || true

  local sel
  sel=$(gum choose --no-limit --selected "Signing,Authentication" \
    --header "Select keys to change (space toggle, a select/unselect all, enter confirm):" \
    "Authentication" "Signing" "Decryption" || true)
  if [ -z "$sel" ]; then
    info "Nothing selected."
    return 0
  fi

  local policy
  policy=$(gum choose --header "Set touch policy for the selected keys to:" "on" "off" || true)
  case "$policy" in
  on | off) ;;
  *)
    info "No policy chosen."
    return 0
    ;;
  esac

  if ! gate "Set touch policy '${policy}' for: ${sel//$'\n'/ }?"; then
    return 0
  fi

  local label slot rc=0
  while IFS= read -r label; do
    if [ -z "$label" ]; then continue; fi
    case "$label" in
    Authentication) slot=aut ;;
    Signing) slot=sig ;;
    Decryption) slot=dec ;;
    *) continue ;;
    esac
    apply_touch "$slot" "$policy" "$label" || rc=1
  done <<<"$sel"

  if [ "$DRY_RUN" != 1 ]; then
    print_status || true
  fi
  if [ "$rc" = 0 ]; then
    ok "Done."
  else
    warn "Completed with errors."
  fi
}

action_status() {
  choose_device || return 0
  print_status || true
}

# ---------------------------------------------------------------------------
# Main menu
# ---------------------------------------------------------------------------
main_menu() {
  hdr "YubiKey OpenPGP Touch Policy"
  if [ "$DRY_RUN" = 1 ]; then
    info "(dry-run: set-touch commands are printed, not executed)"
  fi

  local action
  action=$(gum choose --header "Choose an action:" \
    "Set touch policy" \
    "Show status" \
    "Exit" || true)

  case "$action" in
  "Set touch policy") action_set ;;
  "Show status") action_status ;;
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

main_menu
