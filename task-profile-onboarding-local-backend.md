# Task: Profile Onboarding + Local Backend Runner

## Intent
Let frontend designers run the real profile lifecycle end-to-end **before** the backend is deployed. One Flutter-owned command starts the `backend_v2` profile API + Postgres locally, then launches the app against it. The first product flow gates the main AHMA app behind a **conversational onboarding intake** (variant B) that collects the required profile fields, persists via the real backend, and then replaces hardcoded values (`Sam`, `Mum`, `default_user`) with profile state.

Spans two repos: this frontend repo (`ahma_app/`) + sibling `../backend/` (`backend_v2/`).

## Process Constraints (from user)
- **No git commits at any point** in this task / pipeline. Working-tree changes only; the user commits.
- Implementation runs via a Workflow pipeline (below), gated on explicit user go-ahead.

## Context (grounded findings — 2026-07-06)
Backend (`../backend`, branch `feat/user-profiles-backend-product`, matches spec assumption):
- `backend_v2/app.py` runs Flask on port **5002**. `/health` → `{service: "ahma-backend-v2", database.configured}`. `/api/profile/options` registered unconditionally.
- Profile CRUD routes register **only when `DATABASE_URL` AND `PROFILE_API_ENABLED`** are set. Endpoints: `POST /api/profile` (create-only, 201), `GET /api/profile/<userId>`, `GET /api/profile/<userId>/context`, `PATCH`, `POST /api/profile/resolve`.
- Auth boundary bypassed by `PROFILE_API_ALLOW_UNAUTHENTICATED=true` (else requires `X-API-Key`).
- Error contract: `profile_not_found` 404, `duplicate_user_id` 409, `contact_already_exists`/`contact_conflict` 409, validation errors with per-field detail.
- Migrations: `python -m backend_v2.db migrate` (idempotent, tracked in `schema_migrations`). Single file `backend_v2/migrations/001_user_profiles.sql`.
- **No docker-compose / Postgres definition exists** in backend. Only an app `Dockerfile`.

Frontend (`ahma_app/`):
- `setup_and_run.sh` exists but is **Linux-only** (`sudo service dbus start`, `systemctl start NetworkManager`, `flutter run -d linux`). No `--with-profile-backend` flag yet.
- `.env` has `BACKEND_API_URL=http://localhost:5001` (legacy voice/webhook/transcript backend — a **different** backend from backend_v2 on 5002).
- `shared_preferences: ^2.2.2` is in `pubspec.yaml` but **not used anywhere yet**. Onboarding is fully greenfield.
- Hardcoded values to replace: `Sam`/`Mum` in `voice_call_screen.dart`, `ahma_call_screen.dart`, `profile_screen.dart`; `default_user` in `call_provider.dart`, `webhook_provider.dart`.
- `main.dart` currently picks first screen via a `USE_UNITY_HOME_SCREEN` flag — needs a profile gate.
- `.gitignore` ignores `.env.local` but **not `.local/`** (spec requires `.local/` gitignored).

## Plan (implementation pipeline — Workflow, after go-ahead)
1. review spec — Fable, high
2. address review findings — Opus, high (amend this task/spec)
3. implement against spec — Fable, xhigh (context + goals, NOT a babysitting step-by-step plan)
4. review implementation — Opus, xhigh
5. address review — Fable, high
6. report back

## Acceptance Criteria
Backend / local-runner:
- Docker Postgres up on `55432`; migrations applied against it.
- `GET /health` → `ahma-backend-v2` with `database.configured == true`.
- `GET /api/profile/options` works unauthenticated.
- `POST /api/profile`, `GET /api/profile/:userId`, `GET /api/profile/:userId/context` all work against local Postgres.
- Sibling `../backend` checkout is never auto-pulled or mutated.

Frontend lifecycle:
- First launch (no saved userId) → onboarding; loads backend options.
- Required-field validation errors map to the correct question, recoverable inline.
- Successful create stores `userId` in `shared_preferences`; enters main app.
- Relaunch does `GET` (not `POST`), skips onboarding, shows profile-aware content.
- Stale saved `userId` after backend reset → 404 → clears local identity → onboarding.

Design QA: conversational intake scannable on mobile, large touch targets, all required fields reachable, visible progress cue, error states don't obscure next actions.

## Todo
- [x] Move design doc into this task file
- [x] Review spec (grounded) + surface decisions
- [x] Address issues / amend spec with user (see Review Resolutions)
- [x] (gate) User go-ahead
- [x] Run Workflow pipeline (wf_aa6f32d3-caf) — stages 1–3 + 5 ran; stage 4 misfired (stub payload)
- [x] Re-ran implementation review for real (Opus xhigh) — verdict: correct & spec-compliant, 1 LOW finding
- [x] Addressed LOW finding (immediate resubmit on single-field correction) + analyze clean
- [x] Cleaned pipeline scratch (dup design doc, stray design-review worktree)
- [x] Report back

## Notes
- 2026-07-06: Design doc `profile-onboarding-local-backend-design.md` existed in both frontend and backend roots (identical). Moved frontend copy into this task file. Backend copy still present (housekeeping decision pending).

---

# Spec (canonical — passed to the implementation pipeline)

_Verbatim from `profile-onboarding-local-backend-design.md`, plus resolutions appended under "Review Resolutions" once addressed._

## Summary

Frontend designers need to build and test a real profile lifecycle before the backend is deployed. The solution is a Flutter-owned local runner that starts the backend profile API and Postgres automatically, then launches the app against that local API.

The first product flow gates the main AHMA app behind profile onboarding. The approved design direction is a conversational intake: AHMA asks the required profile questions one at a time, with quick replies for option fields.

## Goals

- Let designers run the Flutter app and profile backend from the frontend repo with one command.
- Exercise the real backend profile API, including validation, persistence, reads, and profile context.
- Avoid requiring designers to manually clone, configure, or run the backend repo.
- Keep the local backend clearly separate from production auth and deployment behavior.
- Keep v1 onboarding limited to required profile fields.

## Non-Goals

- No production authentication.
- No Firebase/Auth0 integration.
- No deployed shared dev backend.
- No in-app debug reset in v1.
- No requirement for Anthropic, Ultravox, Google Calendar, Todoist, or Railway env values for the profile onboarding loop.

## Local Dev Architecture

The primary entrypoint lives in the Flutter app:

```bash
cd frontend/ahma_app
./setup_and_run.sh --with-profile-backend
```

Backend source resolution:

> **SUPERSEDED BY R1.** The `../../backend` sibling branch below is deleted — see R1 for the authoritative `.local/backend`-only resolution. Kept here only for provenance.

```text
if ../../backend exists:            # SUPERSEDED BY R1 — never read/mutate the sibling
  use that checkout as-is
  do not pull or mutate its branch
else if .local/backend exists:
  fetch origin
  checkout the profile backend branch
  pull --ff-only
else:
  clone https://github.com/AHMA-sg/AHMA-backend-BFG.git into .local/backend
  checkout the profile backend branch
```

`.local/` is frontend-local generated state and should be gitignored.

Runtime stack:

```text
Docker Postgres: localhost:55432
backend_v2 Flask app: localhost:5002
Flutter BACKEND_API_URL: http://localhost:5002   # SUPERSEDED BY R3 — profile lifecycle uses PROFILE_API_URL=http://localhost:5002; BACKEND_API_URL stays :5001 (legacy)
```

The script generates local-only profile env:

```text
DATABASE_URL=postgresql://ahma_profile:ahma_profile@localhost:55432/ahma_profile
PROFILE_API_ENABLED=true
PROFILE_API_ALLOW_UNAUTHENTICATED=true
```

The local profile backend is intentionally unauthenticated because auth is out of scope. This must be framed as local-only behavior.

## Onboarding Lifecycle

The main AHMA app is gated behind profile onboarding.

Required fields for v1:

- `userId`
- `displayName`
- `email` or `phone`
- `careRecipient.relationship`
- `careRecipient.displayName`
- `caregiverContext.caregivingDuration`
- `caregiverContext.primaryCaregivingChallenge`
- `caregiverContext.primarySupportNeed`
- `caregiverContext.financialStrainSeverity`

First launch:

```text
Flutter starts
  -> read local userId from shared_preferences
  -> no userId found
  -> show onboarding
  -> load choices from GET /api/profile/options
  -> submit POST /api/profile
  -> save userId in shared_preferences
  -> enter main AHMA experience
```

Returning launch:

```text
Flutter starts
  -> read local userId from shared_preferences
  -> GET /api/profile/:userId
  -> if found: enter main AHMA experience
  -> if 404: clear local userId and show onboarding   # REFINED BY R11 — clear ONLY on JSON error.code == 'profile_not_found'; all other failures are non-destructive/retriable
```

`POST /api/profile` is create-only. Returning launches use `GET`, not `POST`.

## Profile-Aware App Behavior

After onboarding, hardcoded values such as `Sam`, `Mum`, and `default_user` should be replaced by profile state.

Profile screen:

```text
GET /api/profile/:userId
display profile-derived greeting and care recipient details
```

Call start:

```text
GET /api/profile/:userId/context
use profileContext for:
  userName
  careRecipientName
  caregiver relationship/context
  first AHMA greeting
  call metadata
```

Transcript submission should use the saved profile `userId`. Voice and transcript integrations may still require the legacy backend/env; they are not required to verify the profile onboarding lifecycle.

## Onboarding UX Direction

Design-shotgun approved variant: **B. Conversational Intake**.

Artifact directory:

```text
/Users/andrewsoon/.gstack/projects/AHMA-sg-AHMA-backend-BFG/designs/profile-onboarding-20260706-011537
```

Relevant artifacts:

- `design-board.html`
- `design-board-full.png`
- `approved.json`

Approved direction:

```text
AHMA asks required onboarding questions one at a time,
with quick replies for option fields and a warmer care-companion tone.
```

Implementation implications:

- Factual text answers should still feel lightweight, not like a chat transcript that requires excessive typing.
- Option fields should use backend-provided choices from `/api/profile/options`.
- Progress should be visible because the required flow has multiple questions.
- Validation errors should be recoverable inline without clinical or punitive language.
- The success transition should take users directly into the main AHMA experience.

## Persistence

Persistence is split by responsibility:

```text
Flutter shared_preferences = current local userId
Docker Postgres volume = profile rows
```

Postgres data persists through normal Docker restarts because it lives in a named volume. Removing the volume resets backend profile data.

`shared_preferences` is a temporary local identity mechanism only. Production auth will later replace the source of identity while preserving the same product lifecycle shape.

## Reset Behavior

Reset is script-only in v1:

```bash
./setup_and_run.sh --reset-profile-data
```

It should:

- Stop the local profile backend.
- Remove the Docker profile Postgres volume.
- Remove generated backend env/state owned by the script.
- Print a clear note that Flutter may still have a saved local `userId`.

If Flutter has a stale `userId` after reset, the app should recover on next launch:

```text
GET /api/profile/:oldUserId
404 profile_not_found
clear local userId
show onboarding
```

## Failure Behavior

The script should fail early with clear, actionable messages:

- Docker missing: print macOS Docker install guidance and stop.
- Docker daemon stopped: ask the designer to start Docker Desktop or Colima and retry.
- Port `55432` busy: report Postgres port conflict and stop.
- Port `5002` busy: report backend port conflict and stop.
- `.local/backend` pull conflict: stop and explain local changes prevent `--ff-only`.
- Migration failure: stop and show the migration command/log location.
- Backend health failure: stop before launching Flutter.

~~For a sibling `../../backend` checkout, the script must not auto-pull or overwrite local backend work.~~ **SUPERSEDED BY R1** — the sibling checkout is out of the picture; this failure mode no longer exists. See R14 for the revised port-busy / migration / process-lifecycle failure rules.

## Testing Strategy

Backend/local-runner checks:

- Runner-owned Postgres (Docker Compose **or** `docker run`, per R4) starts on `55432` with a named volume.
- Migrations run successfully against the local database.
- `GET /health` returns `ahma-backend-v2` with database configured.
- `GET /api/profile/options` works without auth.
- `POST /api/profile`, `GET /api/profile/:userId`, and `GET /api/profile/:userId/context` work against local Postgres.

Frontend lifecycle checks:

- First launch with no saved `userId` shows onboarding.
- Onboarding loads backend options.
- Required validation errors map to the correct question.
- Successful create stores `userId` in `shared_preferences`.
- Relaunch performs `GET`, skips onboarding, and shows profile-aware content.
- Stale saved `userId` after backend reset clears local identity and shows onboarding.

Design QA:

- Conversational intake remains scannable on mobile.
- Touch targets are large enough.
- Required fields are all reachable.
- The flow has a visible progress cue.
- Error states do not obscure next actions.

## Implementation Assumptions

The implementation plan should use these assumptions unless new repo constraints make them unworkable:

- The hidden backend clone checks out `feat/user-profiles-backend-product`.
- `./setup_and_run.sh --with-profile-backend` starts the profile backend, verifies health, then starts Flutter.
- The frontend script is the designer-facing orchestrator. Backend-specific setup can be delegated to a backend helper script if that keeps the boundary cleaner, but designers still run only the Flutter script.
- A developer-only backend-only flag can be added later, but it is not required for the first designer workflow.

---

## Review Resolutions (AUTHORITATIVE — override the verbatim spec above where they conflict)

Decided with the user on 2026-07-06. These win over the original spec text.

### R1 — Backend source: `.local/` only; `../backend` is out of the picture
Delete the sibling-checkout branch entirely. The runner never reads or mutates `../../backend`. Resolution simplifies to:

```text
if .local/backend exists:
  git -C .local/backend fetch origin
  git -C .local/backend checkout feat/user-profiles-backend-product
  git -C .local/backend pull --ff-only
else:
  git clone https://github.com/AHMA-sg/AHMA-backend-BFG.git .local/backend
  git -C .local/backend checkout feat/user-profiles-backend-product
```

Consequences:
- Drop the "sibling `../../backend` must not be auto-pulled" failure mode — no longer relevant.
- All backend runtime state (clone, generated env, Postgres data/compose) lives under `.local/` and must be gitignored.

### R2 — New macOS-first runner; no fidelity to the Linux script
The current `setup_and_run.sh` (DBus / NetworkManager / `flutter run -d linux`) is Linux-specific baggage. Build a **new, macOS-first profile runner** for this use case — take inspiration only. Do **not** preserve the DBus/NetworkManager steps and do **not** hardcode `-d linux` (select the Flutter device appropriately for macOS, or let Flutter choose). Entry points from the spec (`--with-profile-backend`, `--reset-profile-data`) still apply; whether they live in a rewritten `setup_and_run.sh` or a dedicated new script is the implementer's call.

### R3 — Flutter config: separate `PROFILE_API_URL`, keep `BACKEND_API_URL`
The profile API (`:5002`) and legacy voice/webhook/transcript backend (`:5001`) are different services. Introduce a dedicated base URL rather than repointing the existing one:

```text
PROFILE_API_URL=http://localhost:5002   # NEW — profile onboarding lifecycle
BACKEND_API_URL=http://localhost:5001   # UNCHANGED — legacy voice/webhook/transcript
```

The profile lifecycle (options / create / get / context) uses `PROFILE_API_URL`. Do not regress legacy integrations. Wire `PROFILE_API_URL` through `env_config.dart` and a profile API client/datasource.

### R4 — Postgres is frontend-owned under `.local/`
No Postgres/compose exists in the backend, and the backend `Dockerfile` is the heavy legacy `:5001` image (irrelevant here). The runner owns Postgres itself: a generated compose file (or `docker run`) under `.local/` bringing up Postgres on `55432` with a **named volume** (so data survives restarts; `--reset-profile-data` removes the volume). The runner then runs migrations against it.

### R5 — Backend runtime: minimal Python env, use the existing migrate command
- Provision a Python venv for the `.local/backend` clone and install a **minimal** dependency set for `backend_v2` (Flask + SQLAlchemy + a Postgres driver such as `psycopg2-binary`). **Do NOT** `pip install -r requirements.txt` — that root file is the heavy legacy stack (LangChain / ChromaDB / sentence-transformers) for the `:5001` app and would make setup huge and slow. Determine `backend_v2`'s actual imports and install only those.
- Run migrations with the existing command: `DATABASE_URL=… python -m backend_v2.db migrate` (idempotent; tracked in `schema_migrations`). "Migration failure" guidance should reference this exact command.
- Start the app: `backend_v2/app.py` serves on `5002` and only mounts profile CRUD routes when both `DATABASE_URL` and `PROFILE_API_ENABLED` are set.

### R6 — `userId` generation (client-owned)
`userId` is a client-supplied, create-only field. The Flutter client generates a UUID v4 at onboarding submit and persists it in `shared_preferences` **only after** a `201`. On `duplicate_user_id` (409) — practically impossible with a fresh UUID — regenerate and retry once.

### R7 — Sharpen the health gate before launching Flutter
`/health` returns `200` even with no DB. The runner must assert `database.configured == true` (and ideally that a profile route responds, since CRUD routes only mount when `DATABASE_URL` + `PROFILE_API_ENABLED` are present) before starting Flutter — not merely a `200`.

### R8 — Map backend error contract to inline onboarding recovery
Backend emits per-field validation errors plus `duplicate_user_id` / `contact_already_exists` / `contact_conflict` (all 409). Onboarding must surface these inline against the right question in warm, non-clinical language. `email` OR `phone` is required (at least one); ask for at least one and validate accordingly.

### R9 — Scope guards
- `POST /api/profile/resolve` (email/phone → userId) exists but is **out of scope for v1** — identity is device-local via `shared_preferences`. Don't build cross-device resolution.
- Add `.local/` to `ahma_app/.gitignore` (currently only `.env.local` is ignored).
- No git commits anywhere in this task/pipeline — working-tree changes only.

### Scope note
With `../backend` out, the implementation edits are **frontend-repo only**; `backend_v2` is consumed unmodified from the `.local/backend` clone.

---

## Review Resolutions — Addendum (AUTHORITATIVE — R10–R22)

Added 2026-07-06 after a second, code-grounded spec review against `backend_v2` (`app.py`, `profile_routes.py`, `profile_validation.py`, `profile_options.py`, `profile_context.py`, `profile_models.py`, `config.py`, `db.py`) and the current frontend (`env_config.dart`). These resolve the review findings and are as authoritative as R1–R9. Where they touch the same topic as R1–R9, they refine (never contradict) them. **Precedence: R1–R9 win; R10–R22 win over the verbatim spec above.** Every wire shape / error code / option value below was confirmed present in the checked-in backend code.

### R10 — Canonical wire contract (pin the shapes the Flutter client codes against)

The profile lifecycle uses `PROFILE_API_URL` (R3, default `http://localhost:5002`). All endpoints below are unauthenticated in local dev (R4/spec). Success and error envelopes are fixed:

- **Success:** top-level `{"success": true, ...}`.
- **Error:** top-level `{"success": false, "error": {"code": <string>, "message": <string>, "fields"?: {<path>: [<code>, ...]}}}` with the HTTP status shown per code in R12. `fields` is present on validation (400) and duplicate/conflict (409) errors, absent otherwise.

**GET `/api/profile/options`** (unconditionally mounted; no DB needed) →
```json
{"success": true, "options": {
  "caregiverContext": {
    "caregivingDuration": [{"value": "less_than_1_month", "label": "Less than 1 month"}, ...],
    "primaryCaregivingChallenge": [{"value": "emotional_burnout", "label": "Emotional burnout"}, ...],
    "secondaryCaregivingChallenges": [ ...same set as primaryCaregivingChallenge... ],
    "primarySupportNeed": [{"value": "emotional_support", "label": "Emotional support"}, ...],
    "secondarySupportNeeds": [ ...same set as primarySupportNeed... ],
    "financialStrainSeverity": [{"value": "none", "label": "None"}, {"value": "mild", ...}, {"value": "moderate", ...}, {"value": "high", ...}, {"value": "urgent", ...}],
    "existingSupportNetwork": [{"value": "none", ...}, {"value": "family", ...}, ...]
  },
  "careRecipient": {"relationship": [{"value": "parent", "label": "Parent"}, {"value": "spouse", ...}, ..., {"value": "other", "label": "Other"}]}
}}
```
Every choice is `{value, label}`. **Quick replies render `label`, submit `value`.** The full confirmed vocabularies (values):
- `caregivingDuration`: `less_than_1_month`, `1_to_6_months`, `6_to_12_months`, `1_to_3_years`, `3_plus_years`
- `primaryCaregivingChallenge` / `secondaryCaregivingChallenges`: `emotional_burnout`, `financial_strain`, `respite_need`, `medical_navigation`, `daily_tasks`, `loneliness`, `emergency_support`
- `primarySupportNeed` / `secondarySupportNeeds`: `emotional_support`, `financial_guidance`, `respite_options`, `care_services`, `medical_appointments`, `daily_task_planning`, `peer_support`
- `financialStrainSeverity`: `none`, `mild`, `moderate`, `high`, `urgent`
- `careRecipient.relationship`: `parent`, `spouse`, `grandparent`, `child`, `sibling`, `relative`, `friend`, `other`
- `existingSupportNetwork` (optional, not asked in v1): `none`, `family`, `friends`, `helper`, `professional_services`, `support_group` (`none` is exclusive)

**POST `/api/profile`** (create-only, 201). Request body — nested, client-generated `userId` (R6). Send ONLY the v1 required fields; omit optional fields entirely (backend defaults arrays to `[]` and optional scalars to `null`):
```json
{
  "userId": "<uuid v4, lowercase canonical>",
  "displayName": "<free text>",
  "email": "<optional>",
  "phone": "<optional, E.164 e.g. +6591234567>",
  "careRecipient": {"relationship": "<option value>", "displayName": "<free text>"},
  "caregiverContext": {
    "caregivingDuration": "<option value>",
    "primaryCaregivingChallenge": "<option value>",
    "primarySupportNeed": "<option value>",
    "financialStrainSeverity": "<option value>"
  }
}
```
At least one of `email` / `phone` must resolve to a non-empty valid value (R8). Success →
```json
{"success": true, "profile": { /* full profile, see below */ }}
```

**Full profile shape** (returned by POST and GET; `createdAt`/`updatedAt` are Z-suffixed ISO-8601 UTC):
```json
{"userId": "...", "displayName": "...", "email": "..."|null, "phone": "..."|null,
 "careRecipient": {"relationship": "...", "displayName": "...", "ageRange": null, "conditionCategory": null},
 "caregiverContext": {"caregivingDuration": "...", "primaryCaregivingChallenge": "...",
   "secondaryCaregivingChallenges": [], "primarySupportNeed": "...", "secondarySupportNeeds": [],
   "financialStrainSeverity": "...", "existingSupportNetwork": []},
 "createdAt": "2026-07-06T...Z", "updatedAt": "2026-07-06T...Z"}
```

**GET `/api/profile/<userId>`** → `{"success": true, "profile": {...}}` (same shape), or 404 `profile_not_found`.

**GET `/api/profile/<userId>/context`** →
```json
{"success": true,
 "profileContext": {"userId": "...", "displayName": "...", "careRecipientName": "...",
   "careRecipientRelationship": "<value>", "caregivingDuration": "<value>",
   "primaryCaregivingChallenge": "<value>", "primarySupportNeed": "<value>", "financialStrainSeverity": "<value>"},
 "startupMetadata": {"userId": "...", "profileContext": { ...same as above... }}}
```
**Important:** `profileContext` scalar fields (`careRecipientRelationship`, `caregivingDuration`, `primaryCaregivingChallenge`, `primarySupportNeed`, `financialStrainSeverity`) are raw option **values** (e.g. `emotional_burnout`), NOT labels. `displayName` and `careRecipientName` are free-text. Any profile-aware UI that needs human-readable challenge/duration text must map values back through the `/api/profile/options` payload; free-text names can be shown directly.

**Out of scope (do not call):** `PATCH /api/profile/<userId>` and `POST /api/profile/resolve` (R9). Freezed models should cover only the create/get/context/options shapes above.

### R11 — Launch identity is cleared ONLY on JSON `profile_not_found`; every other failure is non-destructive

Refines the "Returning launch → if 404 → clear" line. The blueprint only mounts CRUD routes when `DATABASE_URL` **and** `PROFILE_API_ENABLED` are set; if the profile service is down, misconfigured, half-started, or something else is on `:5002`, the same `GET /api/profile/<userId>` yields a connection error, timeout, 5xx, or a generic (HTML) 404 — none of which mean "this user does not exist."

Rules for the returning-launch `GET /api/profile/<userId>`:
- **Clear the saved `userId` and route to onboarding ONLY when** the response is HTTP 404 **with** a JSON body whose `error.code == "profile_not_found"`.
- **Any other outcome is non-destructive:** connection refused, timeout, DNS/socket error, 5xx, HTTP 4xx other than the JSON `profile_not_found`, HTML/non-JSON 404, or JSON-parse failure → **keep the saved `userId`** and show a retriable "Can't reach the profile service" state (with a Retry action). Never enter onboarding on these.
- The first-launch `GET /api/profile/options` load gets the **same** retriable treatment on any failure: show a retriable error, do not fabricate options, do not proceed to submit.

Acceptance criteria (add to the frontend list):
- Backend unreachable/misconfigured at launch with a saved `userId` does **not** clear identity and does **not** show onboarding — it shows a retriable error and recovers when the backend comes up.
- Options-load failure during onboarding shows a retriable error rather than a broken/empty question.

### R12 — Full validation-error vocabulary + field-path → question mapping

Backend validation (400 `validation_error`) returns `fields = {<dotted path>: [<code>, ...]}`. Confirmed codes and their owning question (question numbers per R13):

| Field path | Code(s) | Owning question | User-facing copy (warm, non-clinical) |
|---|---|---|---|
| `displayName` | `required` | Q1 | "What can I call you? Please share a name." |
| `email` | `invalid_email` | Q2 (contact) | "That email doesn't look right — mind checking it?" |
| `phone` | `invalid_phone` | Q2 (contact) | "That phone number doesn't look right. Include the country code, e.g. +65 9123 4567." |
| `email` **and** `phone` | `required_without_contact` (emitted on BOTH fields simultaneously) | Q2 (contact) | Render **once**: "I'll need either an email or a phone number to reach you." |
| `careRecipient.relationship` | `required`, `invalid_option` | Q3 | "Who are you caring for? Pick one that fits best." |
| `careRecipient.displayName` | `required` | Q4 | "What's their name?" |
| `caregiverContext.caregivingDuration` | `required`, `invalid_option` | Q5 | "How long have you been caring for them?" |
| `caregiverContext.primaryCaregivingChallenge` | `required`, `invalid_option` | Q6 | "What's the hardest part right now?" |
| `caregiverContext.primarySupportNeed` | `required`, `invalid_option` | Q7 | "What kind of support would help most?" |
| `caregiverContext.financialStrainSeverity` | `required`, `invalid_option` | Q8 | "How much financial strain are you feeling?" |
| `userId` | `invalid_uuid`, `duplicate` | none (never a question) | Handled per R6: on `duplicate_user_id` (409) regenerate UUID + resubmit once; on repeat or `invalid_uuid`, generic "Something went wrong — let's try that again." |
| `requestBody` | `invalid_json` | none (client bug) | Generic error; should never happen with a well-formed client. |

Notes:
- `required_without_contact` arrives on **two** field paths but MUST render as **one** message on the contact question (R13 Q2).
- Because the v1 client submits option `value`s straight from the options payload, `invalid_option` should not occur in practice; if it does, treat it as a retriable error on the owning question.
- 409 `duplicate_user_id` carries `fields: {"userId": ["duplicate"]}`; 409 `contact_already_exists` carries `fields` like `{"email": ["duplicate"]}` and/or `{"phone": ["duplicate"]}` (see R15). `contact_conflict` (`{"email":["conflict"],"phone":["conflict"]}`) only arises from `/resolve`, which is out of scope (R9) — no handling needed.

### R13 — Canonical conversational-intake question set, ordering, input types, and progress cue

The intake is exactly **8 questions**, asked one at a time, in this fixed order. `userId` is generated silently (R6) and is never a question. Optional profile fields (`secondaryCaregivingChallenges`, `secondarySupportNeeds`, `existingSupportNetwork`, `careRecipient.ageRange`, `careRecipient.conditionCategory`, `caregiverContext.userAgeRange`) are **not asked** in v1 and are omitted from the POST body.

| # | Prompt (warm care-companion tone) | Field(s) | Input type |
|---|---|---|---|
| Q1 | "Hi, I'm AHMA. What can I call you?" | `displayName` | Free text |
| Q2 | "How can I reach you? An email or a phone number works." | `email` OR `phone` (single question, accepts either; ≥1 required) | Free text (see R16 for phone UX) |
| Q3 | "Who are you caring for?" | `careRecipient.relationship` | Quick replies (from options) |
| Q4 | "What's their name?" | `careRecipient.displayName` | Free text |
| Q5 | "How long have you been caring for them?" | `caregiverContext.caregivingDuration` | Quick replies |
| Q6 | "What's the hardest part of caregiving right now?" | `caregiverContext.primaryCaregivingChallenge` | Quick replies |
| Q7 | "What kind of support would help you most?" | `caregiverContext.primarySupportNeed` | Quick replies |
| Q8 | "How much financial strain are you feeling?" | `caregiverContext.financialStrainSeverity` | Quick replies |

- **One contact question, not two.** Q2 collects a single value and the client decides whether it's an email or a phone (e.g. contains `@` → email, else phone) and puts it in the right POST field. Both `email` and `phone` field errors from the backend (incl. the doubled `required_without_contact`) surface on Q2 and render once.
- **Progress cue = "Question N of 8"** (or an 8-step progress indicator). This is the fixed total the Design-QA "visible progress cue" criterion is measured against.
- Free-text answers (Q1, Q2, Q4) should stay lightweight — a single input + send, not a chat transcript demanding paragraphs.
- Copy above is the canonical intent; exact wording may be polished during design QA as long as each question still maps 1:1 to the field(s) and codes in R12.

Acceptance criteria (sharpen the existing ones): a validation error for a given field path routes the user back to exactly the question in the R12 table; the progress cue reads "N of 8".

### R14 — Runner control flow: idempotent re-run, process lifecycle, and revised failure rules

Replaces the always-stop "Port busy" rules (which broke the normal designer loop where the runner's own Postgres + Flask are already up). Disambiguate by **probing**, not by port occupancy alone:

- **Postgres on `55432`:** if the runner's named Postgres container is already running, **reuse it**. If `55432` is occupied by something that is not that container (fails a trivial connect as the profile DB), fail with a clear foreign-conflict message.
- **Backend on `5002`:** if `:5002` answers the R17 strong readiness probe (`/health` → service `ahma-backend-v2`, `database.configured == true`, **and** `GET /api/profile/<random-uuid4>` → JSON 404 `profile_not_found`), **reuse the running backend**. Only a `:5002` occupied by something that fails those probes is a fatal conflict.
- **Process lifecycle:** the Flask app is started in the background with its PID and logs written under `.local/` (e.g. `.local/run/backend.pid`, `.local/run/backend.log`). On the next run or on script exit / Ctrl-C, the runner stops the previously-started backend using the recorded PID. All failure/health messages that reference logs must print the `.local/run/backend.log` path.
- Postgres container may outlive the script (data is in the named volume); only `--reset-profile-data` (R18) tears it down.

Revised failure rules (supersede the "Failure Behavior" bullets that conflict):
- Docker missing / daemon stopped: unchanged (print install / start guidance, stop).
- `55432` occupied by a **foreign** process: stop with a port-conflict message (naming the runner's own container as the thing to look for).
- `5002` occupied by a **foreign** process (fails the readiness probe): stop with a port-conflict message + `.local/run/backend.log` reference.
- Migration failure (after Postgres accepted a connection, per R19): stop and show `DATABASE_URL=… python -m backend_v2.db migrate` plus the log location.
- Health/readiness failure: stop before launching Flutter (R17).

### R15 — `contact_already_exists` is a self-explanatory dead-end in local dev (copy only, no `/resolve`)

Postgres data persists in the named volume while identity is device-local (`shared_preferences`). After a prefs clear or app reinstall (userId lost, profile row remains), re-onboarding with the same email/phone deterministically returns **409 `contact_already_exists`** (backend pre-checks unique normalized email/phone). `/resolve` is out of scope (R9), so there is no in-app cross-device recovery — the copy must make the exit obvious.

On 409 `contact_already_exists` at Q2 submit, render an inline message on the contact question that:
- States the email/phone is already registered locally, and
- Offers two ways out: (a) enter a different email or phone, or (b) run `./setup_and_run.sh --reset-profile-data` to wipe local profile data and start clean.

Do **not** build `/resolve`. This is copy-only.

### R16 — Phone contact UX vs backend normalization (avoid silently-wrong E.164)

`normalize_phone` strips separators and, for bare digits, silently prefixes `+`, then checks `^\+[1-9]\d{7,14}$`. So a bare 8-digit SG local number like `91234567` becomes `+91234567` — a *valid-looking* E.164 under India's country code — and is stored wrong. Backend stays unmodified (scope); fix in the client UX:

- Q2 must collect a **full international phone number**. Prefill / suggest the `+65 ` prefix for Singapore, or when the user types 8 bare digits, client-side prepend `+65` before submitting.
- Submit the normalized international form (e.g. `+6591234567`).
- On `invalid_phone`, use copy that explicitly mentions including the country code (see R12 Q2 copy).
- This is UX-only; do not change backend normalization.

### R17 — Strong, mandatory readiness probe before launching Flutter (sharpens R7)

`/health` only reports `bool(DATABASE_URL)` and the SQLAlchemy engine is created lazily on first request, so `/health` can pass with Postgres down or migrations missing; and `/api/profile/options` is mounted unconditionally, so probing it proves nothing about CRUD mounting or DB connectivity. Make the strong probe **mandatory** (not "ideally"):

1. `GET /health` must return service `ahma-backend-v2` with `database.configured == true`.
2. Then `GET /api/profile/<freshly-generated-uuid4>` **must** return HTTP **404** with JSON body `error.code == "profile_not_found"`.

Probe 2 is the real gate: a JSON `profile_not_found` proves the CRUD blueprint mounted (env vars took effect), Postgres is reachable, and the `users` / `caregiver_profiles` / `care_recipient_profiles` schema exists (the read joins all three tables). Any other status/body (HTML 404, 500, connection error, non-JSON) **fails the gate** — stop before launching Flutter, with a message pointing at `.local/run/backend.log`. The runner reuses this exact probe to decide whether an already-running `:5002` is the profile backend (R14).

Acceptance criteria: add "runner does not launch Flutter unless `GET /api/profile/<random-uuid>` returns JSON `profile_not_found`."

### R18 — `--reset-profile-data` scope (make it unambiguous)

`--reset-profile-data` must:
- Stop the runner-started Flask backend (via the recorded PID, R14).
- Stop **and remove** the runner's Postgres container (a named volume can't be removed while a container is attached).
- Remove the named Postgres volume.
- Remove generated env/state files under `.local/` that the script owns (e.g. `.local/run/*`, generated compose/env).
- **KEEP** the `.local/backend` clone and its Python venv (expensive to recreate, no benefit to deleting).
- Print the existing note that Flutter may still hold a saved local `userId` (which self-heals via R11 on next launch).

Flag combination: `--reset-profile-data` and `--with-profile-backend` **may be combined in one invocation** — reset runs first (teardown), then a fresh start. If given alone, `--reset-profile-data` performs teardown and exits without starting Flutter.

### R19 — Wait for Postgres readiness before migrating

`db.py`'s migration connects immediately with no retry; a freshly started container needs a few seconds to accept connections, so a naive `start container → migrate` races and reports spurious "migration failure (connection refused)" on cold start. Add an explicit wait-for-ready step between container start and `DATABASE_URL=… python -m backend_v2.db migrate`:
- Poll `pg_isready` (or a trivial driver/psql connect) against `localhost:55432` with a bounded timeout (~30–60s).
- Only after Postgres accepts a connection, run migrations.
- Classify as "migration failure" **only** errors that occur after a connection was accepted; pre-acceptance timeouts are a distinct "Postgres didn't come up in time" error.

### R20 — Backend venv: Python ≥ 3.11 floor + minimal runner-owned requirements

`backend_v2/profile_models.py` uses `from datetime import UTC` (Python 3.11+) and modern typing/union syntax. macOS system `python3` can be 3.9, which installs fine then crashes at import time deep in the request path. Refines R5:
- The runner must locate a `python3` **≥ 3.11** (prefer the highest available; verify via `sys.version_info`). If none is found, fail early with guidance (e.g. "install Python 3.11+: `brew install python@3.12`").
- Pin the minimal deps in a **runner-owned** requirements file under `.local/` (NOT the backend root `requirements.txt`, per R5): `flask`, `sqlalchemy>=2`, `psycopg2-binary`. Install these into the `.local/backend` venv.

### R21 — How `PROFILE_API_URL` reaches Flutter (no `.env` mutation)

The app loads bundled `.env.example` then merges the user-owned, gitignored `ahma_app/.env` (which holds a real Ultravox key), and `EnvConfig._hasUsableValue` filters `your_*` / `*_here` placeholders. Wire `PROFILE_API_URL` the same way `backendApiUrl` is wired:
- Add `profileApiUrl` to `EnvConfig` with precedence **dart-define > dotenv (`PROFILE_API_URL`) > fallback**, fallback `= kIsWeb ? '' : 'http://localhost:5002'` (mirroring `backendApiUrl`).
- Document `PROFILE_API_URL=http://localhost:5002` in `.env.example`.
- Because the local default **equals** the fallback, the designer flow needs no `.env` change and no `--dart-define`. **The runner MUST NOT rewrite `ahma_app/.env`** (it holds the user's real secrets). `BACKEND_API_URL` (`:5001`) is untouched (R3).

### R22 — Launch-gate small edges (prefs key, loading state, edit scope, R6 retry)

- **shared_preferences key:** a single documented key `profile_user_id` holds the UUID. Written only after a 201 (R6); read at launch (R11).
- **Launch loading state:** the identity check (`GET /api/profile/<userId>`) runs **above** both home-screen variants. `main.dart` currently jumps straight to `AhmaMainScreen` / `UnityHomeScreen` via `USE_UNITY_HOME_SCREEN`; the profile gate must sit above both, showing a lightweight splash/loading state during the check (and the retriable-error state from R11 on failure).
- **Profile screen is read-only in v1.** `PATCH /api/profile` is out of scope (R9 excludes `/resolve`; R10 also excludes `PATCH`) — do not add profile editing.
- **R6 retry semantics (pin):** on 409 `duplicate_user_id`, the client silently regenerates a fresh UUIDv4 and resubmits the **identical** answers **once**, with no user interaction. A second 409 falls through to the generic inline error (R12 `userId` row). On success, persist the (regenerated) `userId`.

### Acceptance criteria — additions (fold into the lists above)

Backend / local-runner:
- Runner locates Python ≥ 3.11 or fails early with install guidance (R20).
- Runner waits for Postgres readiness before migrating; no spurious cold-start migration failure (R19).
- Runner reuses an already-running profile Postgres/backend on re-run instead of always failing on busy ports (R14).
- Flutter is not launched unless `GET /api/profile/<random-uuid>` returns JSON `profile_not_found` (R17).
- Runner never rewrites `ahma_app/.env` (R21).
- `--reset-profile-data` removes the container + named volume + generated `.local/` state but keeps the clone/venv; may be combined with `--with-profile-backend` (R18).

Frontend lifecycle:
- Backend unreachable/misconfigured at launch does **not** clear a saved `userId` and does **not** show onboarding — shows a retriable error (R11).
- Local identity is cleared only on JSON `profile_not_found` (R11).
- Options-load failure shows a retriable error, not a broken question (R11).
- Each validation error routes to the correct question per the R12 mapping; `required_without_contact` renders once on the contact question (R12/R13).
- `contact_already_exists` shows the self-explanatory recovery copy (R15).
- On `duplicate_user_id`, client regenerates UUID and resubmits once, silently (R22/R6).
- Progress cue reads "N of 8" (R13).
