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

IMAGE=${OPENCODE_SANDBOX_IMAGE:-localhost/opencode-sandbox:latest}
IMAGE_STREAM=${OPENCODE_SANDBOX_IMAGE_STREAM:-}
GATEWAY_HEALTH_URL=${OPENCODE_SANDBOX_GATEWAY_URL:-'http://127.0.0.1:20128/api/monitoring/health'}
STATE_ROOT=${OPENCODE_SANDBOX_STATE:-"${XDG_STATE_HOME:-$HOME/.local/state}/opencode-sandbox"}
CONTAINER_HOME=/home/vesecto
NAME=
PROJECT_PATH=$PWD

usage() {
  printf '%s\n' 'opencode-sandbox [-n NAME] [-p DIR] [-- OPENCODE_ARGS...]
Use the local repository OpenCode environment in an isolated container.
Share the existing host OmniRoute at 127.0.0.1:20128.

  -n, --name NAME  Persistent sandbox name; default: project directory name
  -p, --path DIR   Project directory, mounted at the same path; default: PWD
  -h, --help       Show this help

Start the TUI by default, or pass args: nix run .#opencode-sandbox -- -- --version'
}

fail() {
  printf 'opencode-sandbox: %s\n' "$1" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case $1 in
    -n | --name)
      [ "$#" -ge 2 ] || fail '--name requires a value'
      NAME=$2
      shift 2
      ;;
    -p | --path)
      [ "$#" -ge 2 ] || fail '--path requires a value'
      PROJECT_PATH=$2
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      fail "unknown argument: $1 (use -- before OpenCode arguments)"
      ;;
  esac
done

if [ -z "$NAME" ] && command -v realpath >/dev/null; then
  PROJECT_PATH=$(realpath -- "$PROJECT_PATH") || fail "cannot resolve project directory: $PROJECT_PATH"
fi
[ -d "$PROJECT_PATH" ] || fail "project directory does not exist: $PROJECT_PATH"
if [ -z "$NAME" ]; then
  NAME=$(basename -- "$PROJECT_PATH")
fi
case $NAME in
  '' | .* | *. | *[!a-zA-Z0-9_.-]*) fail 'name must match [a-zA-Z0-9][a-zA-Z0-9_.-]*' ;;
esac
PROJECT_PATH=$(realpath -- "$PROJECT_PATH") || fail "cannot resolve project directory: $PROJECT_PATH"

health=$(curl -sf --max-time 5 "$GATEWAY_HEALTH_URL") || fail "host OmniRoute is unavailable at $GATEWAY_HEALTH_URL; start omniroute.service"
case $health in
  *'"status"'*'"healthy"'*) ;;
  *) fail "host OmniRoute is unhealthy at $GATEWAY_HEALTH_URL" ;;
esac

# The packaged launcher pipes the immutable image stream in; nothing is rebuilt at runtime.
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  [ -n "$IMAGE_STREAM" ] || fail "$IMAGE is unavailable; use its nix-built launcher or set OPENCODE_SANDBOX_IMAGE_STREAM"
  "$IMAGE_STREAM" | docker image load
fi

SANDBOX_HOME="$STATE_ROOT/$NAME/home"
mkdir -p "$SANDBOX_HOME/.config" "$SANDBOX_HOME/.local/share"
[ -f "$STATE_ROOT/$NAME/session-id" ] || uuidgen >"$STATE_ROOT/$NAME/session-id"

# Keep terminal flags absent for real non-interactive command probes and CI.
docker_args=(
  run --rm --interactive
  --name "opencode-sandbox-$NAME-$(date +%s)-$$"
  # Use a per-container tmpfs; image directory modes alone are not writable by uid 1000.
  --tmpfs "/tmp:rw,nosuid,nodev,exec,mode=1777"
  --network=host
  --user "$(id -u):$(id -g)"
  --env "HOME=$CONTAINER_HOME"
  --env "OPENCODE_SANDBOX_NAME=$NAME"
  --env "OPENCODE_SANDBOX_SESSION_ID=$(cat "$STATE_ROOT/$NAME/session-id")"
  --mount "type=bind,src=$SANDBOX_HOME,dst=$CONTAINER_HOME"
  --mount "type=bind,src=$PROJECT_PATH,dst=$PROJECT_PATH"
  --mount "type=bind,src=/etc/resolv.conf,dst=/etc/resolv.conf,readonly"
  --workdir "$PROJECT_PATH"
  --cap-drop=ALL
  --security-opt=no-new-privileges
)
if [ -t 0 ] && [ -t 1 ]; then
  docker_args+=(--tty)
fi
if [ -d "$HOME/.config/glab-cli" ]; then
  docker_args+=(--mount "type=bind,src=$HOME/.config/glab-cli,dst=$CONTAINER_HOME/.config/glab-cli,readonly")
fi
if [ -d "$HOME/.config/gh" ]; then
  docker_args+=(--mount "type=bind,src=$HOME/.config/gh,dst=$CONTAINER_HOME/.config/gh,readonly")
fi

# Decrypt only to the exec environment; never mount a private keyring into the sandbox.
DECRYPT_HELPER=${OPENCODE_SANDBOX_GPG_DECRYPT:-gpg-decrypt-hardened}
if command -v "$DECRYPT_HELPER" >/dev/null && [ -r "$HOME/.config/api_keys/context7_api_key.gpg" ]; then
  if context7_key=$("$DECRYPT_HELPER" --pinentry error "$HOME/.config/api_keys/context7_api_key.gpg" 2>/dev/null | tr -d '\r\n'); then
    if [ -n "$context7_key" ]; then
      docker_args+=(--env "CONTEXT7_API_KEY=$context7_key")
    fi
  else
    printf 'opencode-sandbox: Context7 key was not decrypted; requests will require an available local key\n' >&2
  fi
  unset context7_key
fi

docker_args+=("$IMAGE" opencode "$@")
printf 'opencode-sandbox: starting %s in %s using shared host OmniRoute\n' "$NAME" "$PROJECT_PATH" >&2
exec docker "${docker_args[@]}"
