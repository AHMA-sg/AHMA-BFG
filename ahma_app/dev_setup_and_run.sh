#!/usr/bin/env bash
#
# AHMA local runner (macOS-first).
#
#   ./setup_and_run.sh                          Run the Flutter app only.
#   ./setup_and_run.sh --with-profile-backend   Start the local profile stack
#                                               (backend_v2 + Docker Postgres),
#                                               health-gate it, then run Flutter.
#   ./setup_and_run.sh --reset-profile-data     Stop the profile backend, remove
#                                               the Postgres container + named
#                                               volume + generated .local state.
#                                               May be combined with
#                                               --with-profile-backend for a
#                                               reset-then-fresh-start.
#
# Extra options:
#   --device <id>     Flutter device id (default: macos)
#   --skip-flutter    Developer flag: bring the profile backend up (or reset)
#                     without launching Flutter.
#
# Everything the runner generates lives under ahma_app/.local/ (gitignored):
#   .local/backend    clone of the backend repo (profile branch)
#   .local/venv       Python venv for backend_v2
#   .local/postgres   generated docker-compose for the profile Postgres
#   .local/run        backend.env, backend.pid, backend.log, migrate.log
#
# The runner NEVER touches ahma_app/.env (it holds your real secrets).
# The Flutter app defaults PROFILE_API_URL to http://localhost:5002, which is
# exactly where this script serves the profile API — no .env change needed.

set -u -o pipefail

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$APP_DIR/.local"
BACKEND_DIR="$LOCAL_DIR/backend"
VENV_DIR="$LOCAL_DIR/venv"
VENV_PY="$VENV_DIR/bin/python"
RUN_DIR="$LOCAL_DIR/run"
PG_DIR="$LOCAL_DIR/postgres"
COMPOSE_FILE="$PG_DIR/docker-compose.yml"
REQUIREMENTS_FILE="$LOCAL_DIR/profile-backend-requirements.txt"

BACKEND_REPO_URL="https://github.com/AHMA-sg/AHMA-backend-BFG.git"
BACKEND_BRANCH="feat/user-profiles-backend-product"

PG_CONTAINER="ahma-profile-postgres"
PG_VOLUME="ahma_profile_pgdata"
PG_PORT=55432
PG_USER="ahma_profile"
PG_PASSWORD="ahma_profile"
PG_DB="ahma_profile"
DATABASE_URL="postgresql://${PG_USER}:${PG_PASSWORD}@localhost:${PG_PORT}/${PG_DB}"

PROFILE_PORT=5002
PROFILE_BASE_URL="http://localhost:${PROFILE_PORT}"

BACKEND_ENV_FILE="$RUN_DIR/backend.env"
BACKEND_PID_FILE="$RUN_DIR/backend.pid"
BACKEND_LOG="$RUN_DIR/backend.log"
MIGRATE_LOG="$RUN_DIR/migrate.log"

# Backend process started by THIS invocation (stopped again on exit).
STARTED_BACKEND_PID=""

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
info() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
fail() {
  printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2
  exit 1
}

usage() {
  sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
}

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------
WITH_PROFILE_BACKEND=0
RESET_PROFILE_DATA=0
SKIP_FLUTTER=0
FLUTTER_DEVICE="macos"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-profile-backend) WITH_PROFILE_BACKEND=1 ;;
    --reset-profile-data) RESET_PROFILE_DATA=1 ;;
    --skip-flutter) SKIP_FLUTTER=1 ;;
    --device)
      shift
      [[ $# -gt 0 ]] || fail "--device requires a value (see: flutter devices)"
      FLUTTER_DEVICE="$1"
      ;;
    -h|--help) usage ;;
    *) fail "Unknown option: $1 (see ./setup_and_run.sh --help)" ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Docker helpers
# ---------------------------------------------------------------------------
ensure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    fail "Docker is not installed. On macOS install Docker Desktop \
(https://docs.docker.com/desktop/setup/install/mac-install/) or Colima \
(brew install colima docker && colima start), then re-run this script."
  fi
  if ! docker info >/dev/null 2>&1; then
    fail "The Docker daemon is not running. Start Docker Desktop (or run \
'colima start'), wait for it to come up, then re-run this script."
  fi
}

port_listening() {
  lsof -nP -iTCP:"$1" -sTCP:LISTEN -t >/dev/null 2>&1
}

container_running() {
  [[ "$(docker ps --filter "name=^${PG_CONTAINER}$" --format '{{.Names}}' 2>/dev/null)" == "$PG_CONTAINER" ]]
}

container_exists() {
  [[ "$(docker ps -a --filter "name=^${PG_CONTAINER}$" --format '{{.Names}}' 2>/dev/null)" == "$PG_CONTAINER" ]]
}

# ---------------------------------------------------------------------------
# Reset (--reset-profile-data)
# ---------------------------------------------------------------------------
stop_recorded_backend() {
  if [[ -f "$BACKEND_PID_FILE" ]]; then
    local pid
    pid="$(cat "$BACKEND_PID_FILE" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      info "Stopping profile backend (pid $pid)"
      kill "$pid" 2>/dev/null || true
      # Give it a moment; force if needed.
      for _ in 1 2 3 4 5; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 1
      done
      kill -9 "$pid" 2>/dev/null || true
    fi
    rm -f "$BACKEND_PID_FILE"
  fi
}

reset_profile_data() {
  info "Resetting local profile data"
  ensure_docker

  stop_recorded_backend

  if container_exists; then
    info "Removing Postgres container $PG_CONTAINER"
    docker rm -f "$PG_CONTAINER" >/dev/null 2>&1 || true
  fi
  if docker volume inspect "$PG_VOLUME" >/dev/null 2>&1; then
    info "Removing Postgres volume $PG_VOLUME"
    docker volume rm "$PG_VOLUME" >/dev/null \
      || fail "Could not remove Docker volume $PG_VOLUME. Is another container still using it?"
  fi

  # Generated state owned by this script. The backend clone and its Python
  # venv are intentionally KEPT (expensive to recreate).
  rm -rf "$RUN_DIR" "$PG_DIR"
  rm -f "$REQUIREMENTS_FILE"

  info "Profile data reset complete."
  warn "The Flutter app may still hold a saved local userId. That's fine:"
  warn "on next launch the backend answers 404 profile_not_found, the app"
  warn "clears the stale userId and shows onboarding again."
}

# ---------------------------------------------------------------------------
# Backend source resolution (.local/backend only — never a sibling checkout)
# ---------------------------------------------------------------------------
resolve_backend_source() {
  command -v git >/dev/null 2>&1 || fail "git is required but not installed."
  mkdir -p "$LOCAL_DIR"

  if [[ -d "$BACKEND_DIR/.git" ]]; then
    info "Updating backend clone in .local/backend ($BACKEND_BRANCH)"
    git -C "$BACKEND_DIR" fetch origin \
      || fail "Could not fetch the backend repo. Check your network connection and GitHub access."
    git -C "$BACKEND_DIR" checkout "$BACKEND_BRANCH" >/dev/null 2>&1 \
      || fail "Could not check out branch $BACKEND_BRANCH in .local/backend."
    if ! git -C "$BACKEND_DIR" pull --ff-only >/dev/null 2>&1; then
      fail "Local changes in .local/backend prevent a fast-forward pull. \
The runner never merges for you: either discard your local changes there \
(git -C ahma_app/.local/backend reset --hard origin/$BACKEND_BRANCH) or \
delete ahma_app/.local/backend and re-run to get a fresh clone."
    fi
  else
    info "Cloning backend repo into .local/backend"
    git clone "$BACKEND_REPO_URL" "$BACKEND_DIR" \
      || fail "Could not clone $BACKEND_REPO_URL. Check your network connection and GitHub access."
    git -C "$BACKEND_DIR" checkout "$BACKEND_BRANCH" \
      || fail "Could not check out branch $BACKEND_BRANCH after cloning."
  fi
}

# ---------------------------------------------------------------------------
# Python venv (minimal deps for backend_v2 only — NOT the heavy legacy
# root requirements.txt)
# ---------------------------------------------------------------------------
find_python() {
  local candidate
  for candidate in python3.13 python3.12 python3.11 python3; do
    if command -v "$candidate" >/dev/null 2>&1 \
      && "$candidate" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null; then
      PYTHON_BIN="$(command -v "$candidate")"
      return 0
    fi
  done
  fail "backend_v2 needs Python 3.11 or newer, and none was found. \
Install one with: brew install python@3.12  — then re-run this script."
}

ensure_venv() {
  find_python

  if [[ ! -x "$VENV_PY" ]]; then
    info "Creating Python venv (.local/venv) with $PYTHON_BIN"
    "$PYTHON_BIN" -m venv "$VENV_DIR" || fail "Could not create the Python venv at .local/venv."
  fi

  cat > "$REQUIREMENTS_FILE" <<'EOF'
# Minimal runtime deps for backend_v2 (profile API) only.
# Deliberately NOT the backend root requirements.txt, which is the heavy
# legacy :5001 stack (LangChain / ChromaDB / sentence-transformers).
flask>=3,<4
sqlalchemy>=2,<3
psycopg2-binary>=2.9
EOF

  local stamp="$VENV_DIR/.requirements-sha"
  local want_sha
  want_sha="$(shasum -a 256 "$REQUIREMENTS_FILE" | awk '{print $1}')"
  if [[ ! -f "$stamp" || "$(cat "$stamp" 2>/dev/null)" != "$want_sha" ]]; then
    info "Installing backend_v2 Python dependencies (flask, sqlalchemy, psycopg2-binary)"
    "$VENV_PY" -m pip install --quiet --upgrade pip \
      || fail "pip upgrade failed inside .local/venv."
    "$VENV_PY" -m pip install --quiet -r "$REQUIREMENTS_FILE" \
      || fail "Could not install backend dependencies. See pip output above."
    printf '%s' "$want_sha" > "$stamp"
  fi
}

# ---------------------------------------------------------------------------
# Postgres (runner-owned, named volume, port 55432)
# ---------------------------------------------------------------------------
write_compose_file() {
  mkdir -p "$PG_DIR"
  cat > "$COMPOSE_FILE" <<EOF
# Generated by setup_and_run.sh — local profile Postgres. Do not edit.
services:
  profile-postgres:
    image: postgres:16-alpine
    container_name: ${PG_CONTAINER}
    ports:
      - "${PG_PORT}:5432"
    environment:
      POSTGRES_USER: ${PG_USER}
      POSTGRES_PASSWORD: ${PG_PASSWORD}
      POSTGRES_DB: ${PG_DB}
    volumes:
      - ${PG_VOLUME}:/var/lib/postgresql/data

volumes:
  ${PG_VOLUME}:
    name: ${PG_VOLUME}
EOF
}

ensure_postgres() {
  if container_running; then
    info "Reusing running Postgres container $PG_CONTAINER"
  else
    if port_listening "$PG_PORT"; then
      fail "Port $PG_PORT is in use by something that is not the runner's \
Postgres container ($PG_CONTAINER). Stop whatever is listening on $PG_PORT \
(check: lsof -nP -iTCP:$PG_PORT -sTCP:LISTEN) and re-run."
    fi
    write_compose_file
    info "Starting Postgres on localhost:$PG_PORT (named volume: $PG_VOLUME)"
    if docker compose version >/dev/null 2>&1; then
      docker compose -f "$COMPOSE_FILE" up -d >/dev/null \
        || fail "docker compose could not start the profile Postgres container."
    elif container_exists; then
      docker start "$PG_CONTAINER" >/dev/null \
        || fail "Could not start the existing $PG_CONTAINER container."
    else
      docker run -d \
        --name "$PG_CONTAINER" \
        -p "${PG_PORT}:5432" \
        -e POSTGRES_USER="$PG_USER" \
        -e POSTGRES_PASSWORD="$PG_PASSWORD" \
        -e POSTGRES_DB="$PG_DB" \
        -v "${PG_VOLUME}:/var/lib/postgresql/data" \
        postgres:16-alpine >/dev/null \
        || fail "docker run could not start the profile Postgres container."
    fi
  fi

  # Wait for Postgres to actually accept connections (a fresh container
  # needs a few seconds) BEFORE migrating, so cold starts don't misreport
  # connection refusals as migration failures.
  info "Waiting for Postgres to accept connections"
  local attempt
  for attempt in $(seq 1 60); do
    if "$VENV_PY" - <<EOF 2>/dev/null
import psycopg2
psycopg2.connect(
    host="localhost", port=${PG_PORT}, user="${PG_USER}",
    password="${PG_PASSWORD}", dbname="${PG_DB}", connect_timeout=2,
).close()
EOF
    then
      return 0
    fi
    sleep 1
  done
  fail "Postgres did not come up on localhost:$PG_PORT within 60s. \
Check the container: docker logs $PG_CONTAINER"
}

run_migrations() {
  mkdir -p "$RUN_DIR"
  info "Applying database migrations (python -m backend_v2.db migrate)"
  if ! (cd "$BACKEND_DIR" && env DATABASE_URL="$DATABASE_URL" "$VENV_PY" -m backend_v2.db migrate) \
    > "$MIGRATE_LOG" 2>&1; then
    cat "$MIGRATE_LOG" >&2
    fail "Migrations failed (Postgres was reachable, so this is a real \
migration error). Re-run manually with:
  cd ahma_app/.local/backend && DATABASE_URL=$DATABASE_URL $VENV_PY -m backend_v2.db migrate
Full log: ahma_app/.local/run/migrate.log"
  fi
  sed 's/^/    /' "$MIGRATE_LOG"
}

# ---------------------------------------------------------------------------
# Profile backend (backend_v2 Flask app on :5002)
# ---------------------------------------------------------------------------

# Strong readiness probe (the real health gate):
#  1. /health must report service ahma-backend-v2 AND database.configured == true
#  2. GET /api/profile/<fresh uuid4> must return HTTP 404 with a JSON body
#     whose error.code == "profile_not_found" — this proves the CRUD routes
#     mounted (env took effect), Postgres is reachable, and the profile
#     schema exists. Anything else fails the gate.
probe_backend() {
  "$VENV_PY" - <<EOF >/dev/null 2>&1
import json, sys, uuid
import urllib.error, urllib.request

base = "${PROFILE_BASE_URL}"
try:
    with urllib.request.urlopen(base + "/health", timeout=3) as response:
        health = json.load(response)
    if health.get("service") != "ahma-backend-v2":
        sys.exit(1)
    if health.get("database", {}).get("configured") is not True:
        sys.exit(1)

    probe_id = str(uuid.uuid4())
    try:
        urllib.request.urlopen(f"{base}/api/profile/{probe_id}", timeout=3)
        sys.exit(1)  # 200 for a random uuid means this is NOT our backend
    except urllib.error.HTTPError as err:
        if err.code != 404:
            sys.exit(1)
        body = json.load(err)
        if body.get("error", {}).get("code") != "profile_not_found":
            sys.exit(1)
    sys.exit(0)
except SystemExit:
    raise
except Exception:
    sys.exit(1)
EOF
}

write_backend_env() {
  mkdir -p "$RUN_DIR"
  cat > "$BACKEND_ENV_FILE" <<EOF
# Generated by setup_and_run.sh — LOCAL-ONLY profile backend env.
# PROFILE_API_ALLOW_UNAUTHENTICATED bypasses the API-key boundary and must
# never be used outside local development.
DATABASE_URL=${DATABASE_URL}
PROFILE_API_ENABLED=true
PROFILE_API_ALLOW_UNAUTHENTICATED=true
EOF
}

ensure_backend() {
  if port_listening "$PROFILE_PORT"; then
    if probe_backend; then
      info "Reusing healthy profile backend already running on :$PROFILE_PORT"
      return 0
    fi
    fail "Port $PROFILE_PORT is in use but does not answer the profile-backend \
readiness probe, so it is either a foreign process or a broken backend. \
Stop it (check: lsof -nP -iTCP:$PROFILE_PORT -sTCP:LISTEN) and re-run. \
If it was started by this script, see ahma_app/.local/run/backend.log"
  fi

  # Stop any stale backend we started on a previous run.
  stop_recorded_backend

  write_backend_env
  info "Starting profile backend (backend_v2) on :$PROFILE_PORT"
  (
    cd "$BACKEND_DIR"
    set -a
    # shellcheck disable=SC1090
    source "$BACKEND_ENV_FILE"
    set +a
    nohup "$VENV_PY" -m backend_v2.app >> "$BACKEND_LOG" 2>&1 &
    echo $! > "$BACKEND_PID_FILE"
  )
  STARTED_BACKEND_PID="$(cat "$BACKEND_PID_FILE")"

  info "Waiting for the profile backend readiness gate"
  local attempt
  for attempt in $(seq 1 30); do
    if probe_backend; then
      info "Profile backend is ready: $PROFILE_BASE_URL (health + profile routes + database)"
      return 0
    fi
    if ! kill -0 "$STARTED_BACKEND_PID" 2>/dev/null; then
      break
    fi
    sleep 1
  done

  fail "The profile backend did not pass the readiness gate \
(/health database.configured and JSON profile_not_found probe). Flutter was \
NOT launched. Inspect the log: ahma_app/.local/run/backend.log"
}

# Stop a backend that THIS invocation started when the script exits
# (Ctrl-C included). A reused, already-running backend is left alone; the
# Postgres container also keeps running — data lives in the named volume.
cleanup() {
  if [[ -n "$STARTED_BACKEND_PID" ]] && kill -0 "$STARTED_BACKEND_PID" 2>/dev/null; then
    info "Stopping profile backend (pid $STARTED_BACKEND_PID)"
    kill "$STARTED_BACKEND_PID" 2>/dev/null || true
    rm -f "$BACKEND_PID_FILE"
  fi
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
# Flutter
# ---------------------------------------------------------------------------
run_flutter() {
  command -v flutter >/dev/null 2>&1 \
    || fail "Flutter not found in PATH. Install it from https://docs.flutter.dev/get-started/install/macos"

  info "Fetching Flutter dependencies"
  (cd "$APP_DIR" && flutter pub get) || fail "flutter pub get failed."

  info "Launching Flutter app (device: $FLUTTER_DEVICE)"
  local flutter_args=(run -d "$FLUTTER_DEVICE")
  if [[ -f "$APP_DIR/.env" ]]; then
    # Desktop debug apps can be denied runtime reads of project files by macOS.
    # Dart defines are injected by the Flutter tool before launch, so secrets
    # stay local and the app does not need to read .env at runtime.
    flutter_args+=(--dart-define-from-file=.env)
  else
    warn "No ahma_app/.env found; Flutter will use bundled .env.example defaults."
  fi

  (cd "$APP_DIR" && flutter "${flutter_args[@]}")
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if [[ $RESET_PROFILE_DATA -eq 1 ]]; then
  reset_profile_data
  if [[ $WITH_PROFILE_BACKEND -eq 0 ]]; then
    exit 0
  fi
  info "Continuing with a fresh profile backend start"
fi

if [[ $WITH_PROFILE_BACKEND -eq 1 ]]; then
  ensure_docker
  resolve_backend_source
  ensure_venv
  ensure_postgres
  run_migrations
  ensure_backend
  info "Profile stack ready — PROFILE_API_URL default ($PROFILE_BASE_URL) matches; ahma_app/.env was not touched."
fi

if [[ $SKIP_FLUTTER -eq 1 ]]; then
  info "--skip-flutter set: leaving the profile backend running (pid file: .local/run/backend.pid)"
  # Don't stop the backend we just started — the whole point of
  # --skip-flutter is to keep the stack up for manual testing.
  STARTED_BACKEND_PID=""
  exit 0
fi

run_flutter
