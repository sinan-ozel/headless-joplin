#!/usr/bin/env bash
# Headless Joplin entrypoint: configure from env, start the Data API, forward it
# to all interfaces, and sync with WebDAV. See docs/architecture.md.
set -euo pipefail

log() { echo "[entrypoint] $*" >&2; }
die() { log "ERROR: $*"; exit 1; }

API_PORT="${JOPLIN_API_PORT:-41184}"
INTERNAL_PORT="${JOPLIN_INTERNAL_PORT:-41185}"
PROFILE_DIR="${JOPLIN_PROFILE_DIR:-/data/profile}"
SYNC_URL="${JOPLIN_WEBDAV_SYNC_URL:-}"
SYNC_PATH="${JOPLIN_WEBDAV_SYNC_PATH:-/}"
SYNC_INTERVAL="${JOPLIN_WEBDAV_SYNC_INTERVAL_MINUTES:-5}"
SYNC_ON_START="${JOPLIN_WEBDAV_SYNC_ON_START:-true}"
LOG_LEVEL="${JOPLIN_LOG_LEVEL:-info}"

[ -n "${JOPLIN_API_TOKEN:-}" ] || die "JOPLIN_API_TOKEN is required"
[[ "$SYNC_INTERVAL" =~ ^[0-9]+$ ]] || die "JOPLIN_WEBDAV_SYNC_INTERVAL_MINUTES must be a non-negative integer"
[ "$API_PORT" != "$INTERNAL_PORT" ] || die "JOPLIN_API_PORT and JOPLIN_INTERNAL_PORT must differ"

# Re-exec as an unprivileged user that owns the profile directory.
if [ "$(id -u)" = 0 ]; then
  PUID="${PUID:-1000}"
  PGID="${PGID:-1000}"
  mkdir -p "$PROFILE_DIR"
  chown -R "$PUID:$PGID" "$PROFILE_DIR"
  export HOME="$PROFILE_DIR"
  exec setpriv --reuid="$PUID" --regid="$PGID" --clear-groups "$0" "$@"
fi
mkdir -p "$PROFILE_DIR"

joplin_cmd() { joplin --profile "$PROFILE_DIR" --log-level "$LOG_LEVEL" "$@"; }

# Bare host -> https://; an explicit scheme is used as given.
webdav_url() {
  local url="$SYNC_URL" path="$SYNC_PATH"
  [[ "$url" =~ ^https?:// ]] || url="https://$url"
  url="${url%/}"
  [[ "$path" == /* ]] || path="/$path"
  if [ "$path" = "/" ]; then echo "$url"; else echo "$url$path"; fi
}

sync_once() {
  joplin_cmd sync || log "sync failed (will retry)"
  if [ -n "${JOPLIN_E2EE_PASSWORD:-}" ]; then
    joplin_cmd e2ee decrypt --password "$JOPLIN_E2EE_PASSWORD" || log "e2ee decrypt failed"
  fi
}

# --- configure (must finish before any other joplin process starts) ---
joplin_cmd config api.token "$JOPLIN_API_TOKEN" >/dev/null
joplin_cmd config api.port "$INTERNAL_PORT" >/dev/null
if [ -n "$SYNC_URL" ]; then
  joplin_cmd config sync.target 6 >/dev/null   # 6 = WebDAV
  joplin_cmd config sync.6.path "$(webdav_url)" >/dev/null
  joplin_cmd config sync.6.username "${JOPLIN_WEBDAV_SYNC_USERNAME:-}" >/dev/null
  joplin_cmd config sync.6.password "${JOPLIN_WEBDAV_SYNC_PASSWORD:-}" >/dev/null
  log "sync target: $(webdav_url)"
else
  joplin_cmd config sync.target 0 >/dev/null
  log "JOPLIN_WEBDAV_SYNC_URL unset: sync disabled"
fi

if [ -n "$SYNC_URL" ] && [ "$SYNC_ON_START" = "true" ]; then
  log "initial sync"
  sync_once
fi

# --- run ---
pids=()
cleanup() { kill "${pids[@]}" 2>/dev/null || true; }
trap 'cleanup; exit 143' TERM INT

joplin_cmd server start &
pids+=($!)

# Open the public port only once Joplin answers, so clients never hit a dead socket.
until node -e "fetch('http://127.0.0.1:$INTERNAL_PORT/ping').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))"; do
  kill -0 "${pids[0]}" 2>/dev/null || die "joplin server exited during startup"
  sleep 1
done

socat "TCP-LISTEN:$API_PORT,fork,reuseaddr" "TCP:127.0.0.1:$INTERNAL_PORT" &
pids+=($!)
log "Data API on :$API_PORT"

if [ -n "$SYNC_URL" ] && [ "$SYNC_INTERVAL" -gt 0 ]; then
  ( while sleep "$((SYNC_INTERVAL * 60))"; do sync_once; done ) &
  pids+=($!)
fi

# If any process dies, take the container down so the orchestrator restarts it.
status=0
wait -n || status=$?
log "a child process exited (status $status), shutting down"
cleanup
exit "$status"
