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
set -euo pipefail

HERE=$(dirname "$0")
TMP=$(mktemp -d)
trap 'find "$TMP" -delete' EXIT
FAILURES=0

fail() {
  printf 'FAIL %s\n' "$1" >&2
  FAILURES=$((FAILURES + 1))
}

new_case() {
  CASE_DIR="$TMP/$1"
  mkdir -p "$CASE_DIR/bin" "$CASE_DIR/project" "$CASE_DIR/home" "$CASE_DIR/state"
  bash_bin=$(command -v bash)
  : > "$CASE_DIR/docker.log"
  {
    printf '#!%s\n' "$bash_bin"
    cat <<'STUB'
printf '%s\n' "$*" >> "$FAKE_DOCKER_LOG"
case "$1 $2" in
  'image inspect') exit 1 ;;
  'image load') cat >/dev/null ;;
  'run '*)
    printf '%s\n' "$FAKE_DOCKER_LOG" >/dev/null
    [ -n "${FAKE_DOCKER_STDOUT:-}" ] && printf '%s\n' "$FAKE_DOCKER_STDOUT"
    ;;
esac
STUB
  } > "$CASE_DIR/bin/docker"
  {
    printf '#!%s\n' "$bash_bin"
    cat <<'STUB'
printf '%s\n' "$*" >> "$FAKE_CURL_LOG"
[ "${FAKE_GATEWAY_HEALTHY:-1}" -eq 1 ] && printf '{"status":"healthy"}\n'
exit "${FAKE_GATEWAY_EXIT:-0}"
STUB
  } > "$CASE_DIR/bin/curl"
  {
    printf '#!%s\n' "$bash_bin"
    cat <<'STUB'
printf 'stream executed\n' >> "$FAKE_IMAGE_STREAM_LOG"
printf 'fake tar stream\n'
STUB
  } > "$CASE_DIR/image-stream"
  chmod +x "$CASE_DIR/bin/docker" "$CASE_DIR/bin/curl" "$CASE_DIR/image-stream"
  : > "$CASE_DIR/curl.log"
  : > "$CASE_DIR/image-stream.log"
  export CASE_DIR
  export FAKE_DOCKER_LOG="$CASE_DIR/docker.log"
  export FAKE_CURL_LOG="$CASE_DIR/curl.log"
  export FAKE_IMAGE_STREAM_LOG="$CASE_DIR/image-stream.log"
  export OPENCODE_SANDBOX_IMAGE='localhost/opencode-sandbox:test'
  export OPENCODE_SANDBOX_IMAGE_STREAM="$CASE_DIR/image-stream"
}

run_sandbox() {
  set +e
  OUTPUT=$(PATH="$CASE_DIR/bin:$PATH" HOME="$CASE_DIR/home" OPENCODE_SANDBOX_STATE="$CASE_DIR/state" bash "$HERE/launcher.sh" "$@" 2>&1)
  STATUS=$?
  set -e
}

require_log() {
  needle=$1
  label=$2
  grep -F -- "$needle" "$FAKE_DOCKER_LOG" >/dev/null || fail "$label: missing $needle; output=$OUTPUT; log=$(cat "$FAKE_DOCKER_LOG")"
}

new_case failure
run_sandbox --path "$CASE_DIR/missing"
[ "$STATUS" -ne 0 ] || fail 'nonexistent project must fail'
[ -s "$FAKE_DOCKER_LOG" ] && fail 'invalid project starts docker' || true

new_case bad_name
run_sandbox --name ../bad
[ "$STATUS" -ne 0 ] || fail 'invalid sandbox name must fail'
[ -s "$FAKE_DOCKER_LOG" ] && fail 'invalid name starts docker' || true

new_case gateway_down
export FAKE_GATEWAY_EXIT=22
run_sandbox --path "$CASE_DIR/project"
[ "$STATUS" -ne 0 ] || fail 'unhealthy gateway must fail'
unset FAKE_GATEWAY_EXIT

new_case first
export FAKE_DOCKER_STDOUT='opencode probe'
run_sandbox --name alpha --path "$CASE_DIR/project" -- --version
[ "$STATUS" -eq 0 ] || fail "valid launch failed: $OUTPUT"
require_log '--network=host' 'host network'
require_log '--tmpfs /tmp:rw,nosuid,nodev,exec,mode=1777' 'writable temporary filesystem'
require_log '--mount type=bind,src='"$CASE_DIR/state/alpha/home"',dst=/home/vesecto' 'per-sandbox home'
require_log 'localhost/opencode-sandbox:test opencode --version' 'arguments forwarded verbatim'
require_log "--mount type=bind,src=$CASE_DIR/project,dst=$CASE_DIR/project" 'project keeps its absolute path'
require_log '--mount type=bind,src=/etc/resolv.conf,dst=/etc/resolv.conf,readonly' 'DNS uses host resolver'
require_log 'image load' 'local image load'
[ -s "$FAKE_IMAGE_STREAM_LOG" ] || fail 'packaged image stream was not executed'
[ -d "$CASE_DIR/state/alpha/home" ] || fail 'home was not created'
grep -F -- '--tty' "$FAKE_DOCKER_LOG" >/dev/null && fail 'non-TTY launch requested a TTY' || true

new_case second
run_sandbox --name beta --path "$CASE_DIR/project" -- run 'exact prompt'
require_log "--mount type=bind,src=$CASE_DIR/state/beta/home,dst=/home/vesecto" 'second sandbox isolation'
require_log 'run exact prompt' 'opencode run arguments'

new_case context7
mkdir -p "$CASE_DIR/home/.config/api_keys"
printf 'encrypted fixture\n' >"$CASE_DIR/home/.config/api_keys/context7_api_key.gpg"
{
  printf '#!%s\n' "$bash_bin"
  cat <<'STUB'
printf '%s\n' "$*" >> "$FAKE_DECRYPT_LOG"
printf 'fake-context7-key\n'
STUB
} >"$CASE_DIR/bin/gpg-decrypt-hardened"
chmod +x "$CASE_DIR/bin/gpg-decrypt-hardened"
export FAKE_DECRYPT_LOG="$CASE_DIR/decrypt.log"
: >"$FAKE_DECRYPT_LOG"
run_sandbox --name secret --path "$CASE_DIR/project" -- --version
[ "$STATUS" -eq 0 ] || fail "encrypted Context7 launch failed: $OUTPUT"
require_log '--env CONTEXT7_API_KEY=fake-context7-key' 'hardened Context7 decryption'
grep -F -- "--pinentry error $CASE_DIR/home/.config/api_keys/context7_api_key.gpg" "$FAKE_DECRYPT_LOG" >/dev/null \
  || fail 'hardened decryptor call mismatch'

new_case help
run_sandbox --help
[ "$STATUS" -eq 0 ] || fail 'help failed'
[ -s "$FAKE_DOCKER_LOG" ] && fail 'help must not touch docker' || true

if [ "$FAILURES" -ne 0 ]; then
  printf '%s launcher scenario(s) failed\n' "$FAILURES" >&2
  exit 1
fi
printf 'PASS launcher scenarios\n'
