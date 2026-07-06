# Local dev runner — `dev_setup_and_run.sh`

One command to run the Flutter app, optionally with a fully local profile
backend (Flask `backend_v2` + a throwaway Postgres) wired up for you. macOS-first.

Run everything from `ahma_app/`.

## What it does

- **App only:** fetches Flutter deps and launches the app.
- **`--with-profile-backend`:** additionally clones/updates the backend repo into
  `.local/`, creates a Python venv, starts a Dockerised Postgres, runs migrations,
  boots the profile API on **:5002**, and health-gates it before Flutter launches.
  If the gate fails, Flutter is **not** started and you get the backend log path.

The app defaults `PROFILE_API_URL` to `http://localhost:5002` — exactly where the
runner serves the profile API, so **you never edit `.env`**. The runner never
touches `ahma_app/.env` (your real secrets live there).

## Prerequisites

| Need | Only for | Install |
|------|----------|---------|
| Flutter | always | https://docs.flutter.dev/get-started/install/macos |
| git + GitHub access to `AHMA-sg/AHMA-backend-BFG` | `--with-profile-backend` | you likely already have this |
| Docker (Desktop or Colima) running | `--with-profile-backend` | `brew install colima docker && colima start` |
| Python ≥ 3.11 | `--with-profile-backend` | `brew install python@3.12` |

The script checks each of these and tells you exactly what to fix if one is missing.

## Quick start

```bash
cd ahma_app

# App only (no backend)
./dev_setup_and_run.sh

# App + local profile backend (the usual full-stack dev loop)
./dev_setup_and_run.sh --with-profile-backend

# Wipe local profile data (DB container + volume + generated state), then start fresh
./dev_setup_and_run.sh --reset-profile-data --with-profile-backend
```

First `--with-profile-backend` run takes a few minutes (clone + venv + pip +
pull the Postgres image). Later runs reuse everything and start fast.

## Flags

| Flag | Effect |
|------|--------|
| `--with-profile-backend` | Bring up Postgres + profile API on :5002, then run Flutter. |
| `--reset-profile-data` | Stop the backend, remove the Postgres container + named volume + generated `.local` state. Combine with `--with-profile-backend` for reset-then-fresh-start. |
| `--device <id>` | Flutter device id (default `macos`; see `flutter devices`). |
| `--skip-flutter` | Bring the backend up (or reset) but don't launch Flutter — leaves the stack running for manual/API testing. |
| `-h`, `--help` | Usage. |

## What runs where

- Profile API: `http://localhost:5002` (`/health`, `/api/profile/...`)
- Postgres: `localhost:55432`, container `ahma-profile-postgres`, named volume
  `ahma_profile_pgdata` (data survives restarts; only `--reset-profile-data` clears it).

## Where state lives

Everything the runner generates is under `ahma_app/.local/` (gitignored — never commit it):

```
.local/backend    clone of the backend repo (profile branch)
.local/venv       Python venv for backend_v2
.local/postgres   generated docker-compose for the local Postgres
.local/run        backend.env, backend.pid, backend.log, migrate.log
```

## Lifecycle notes

- Ctrl-C stops a backend **this run started**; a backend that was already running
  is left alone. The Postgres container also keeps running between sessions —
  data persists in the named volume.
- Re-running is safe: a healthy backend/Postgres already up is reused, not duplicated.
- After a data reset the app may still hold a saved `userId`; that's fine — the
  backend answers `404 profile_not_found`, the app clears it and shows onboarding.

## Troubleshooting

- **Docker not running** → start Docker Desktop / `colima start`, re-run.
- **Port 5002 or 55432 in use** → the script names the check, e.g.
  `lsof -nP -iTCP:5002 -sTCP:LISTEN`; stop that process and re-run.
- **Migrations failed** → full log at `.local/run/migrate.log`; the script prints
  the exact manual re-run command.
- **Backend didn't pass the readiness gate** → inspect `.local/run/backend.log`.
- **Can't fast-forward `.local/backend`** → you have local edits there; either
  `git -C .local/backend reset --hard origin/<branch>` or delete `.local/backend`
  and re-run for a fresh clone.
