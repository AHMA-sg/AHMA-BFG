# Handoff Brief: Login Stub + Real Profile Page (editable)

> **Read this together with `task-profile-onboarding-local-backend.md`.**
> That file is the canonical spec (R1–R22) for the onboarding lifecycle and stays authoritative.
> This brief is a **delta**: three additions that sit on top of the already-built onboarding work and
> amend three specific spec decisions. Where this brief and the task md disagree, **this brief wins for
> the three features below only**; everything else in the task md still holds.

---

## 0. Baseline you are extending (do not rebuild)

The onboarding lifecycle is **already implemented** and committed to branch **`feat/profile-onboarding`**
(off `feat/integrate-backend`). Start your work from there:

```bash
git checkout feat/profile-onboarding
git checkout -b feat/profile-login-and-editing
```

Already built (reuse, don't reinvent):

| Concern | File | Reuse it for |
|---|---|---|
| Launch gate: `checking / onboarding / unreachable / ready` | `lib/presentation/screens/profile_gate.dart` | The login screen sits **above** this. |
| Gate state + `profile` in memory, `completeOnboarding()`, `retry()` | `lib/presentation/providers/profile_provider.dart` | Account screen reads `profileGateProvider.profile`; add an `updateProfile()` + `logout()` here. |
| 8-question conversational intake | `lib/presentation/screens/onboarding_screen.dart` | The "setup stage" the login routes into. Unchanged. |
| Onboarding state machine | `lib/presentation/providers/onboarding_provider.dart` | Unchanged. |
| API client (`getOptions/createProfile/getProfile/getProfileContext`) + typed exceptions + `_request()` helper | `lib/data/datasources/profile_api.dart` | **Add `updateProfile()`** reusing `_request` + the existing exception mapping. |
| Wire models | `lib/data/models/profile_models.dart` | Add a `ProfilePatchRequest` (partial) model. |
| Local identity in `shared_preferences` (`profile_user_id`) | `lib/data/datasources/local_identity_store.dart` | `logout()` clears this. |
| Home dashboard ("Good morning, …") | `lib/presentation/screens/profile_screen.dart` | Add the **top-right entry point** here. |
| Tab host | `lib/presentation/screens/ahma_main_screen.dart` | The dashboard tab lives here (note: the "Profile" *tab* is the dashboard, not an account page). |

**Backend is consumed unmodified.** `backend_v2` on `:5002` already exposes everything you need,
**including PATCH** (see §4). No backend branch is required for these three features.

---

## 1. Feature A — Login stub (simulate auth)

**Intent:** the very first screen is a fake login. There is **no real auth** — any button proceeds.

**Behavior:**
- A new `LoginScreen` becomes the first route, **above** `ProfileGate`.
- Every action (Continue / "Sign in with Google" / "Sign in with Apple" / email field, etc.) does the
  same thing: mark the session "logged in" and hand off to `ProfileGate`.
- `ProfileGate` then behaves exactly as today: no saved `profile_user_id` → onboarding ("setup stage");
  saved + resolves → main app (R11/R22 unchanged).

**Recommended structure:** a thin `authProvider` (a `StateNotifier<bool>` / enum) that `main.dart` gates on:
`loggedOut → LoginScreen`, `loggedIn → ProfileGate(app: …)`. Keep it in memory only (a stub) unless you
want it to survive restarts — if so, store a `logged_in` bool in `LocalIdentityStore` next to
`profile_user_id`.

**Decision to make (pick and note it in the PR):** the user described "first page is login, any button →
setup stage." Literally forcing onboarding after *every* login would break the create-only `POST`
(R6/R10) for a device that already has a profile. **Recommended:** login is cosmetic — it always routes
into `ProfileGate`, which decides onboarding-vs-app from saved identity. On a fresh device that *is* the
setup stage; on a returning device it lands in the app. If a demo truly needs "always show setup," gate
that behind a debug flag, not the default path.

**Amends:** task md **Non-Goals** ("No production authentication" / "No Firebase/Auth0"). Still true —
this is a **stub only**, explicitly not real auth. Do not add real credential checks, OAuth, or tokens.

**Acceptance:**
- Cold start with no saved identity: LoginScreen → (any button) → onboarding → app.
- Cold start with saved+valid identity: LoginScreen → (any button) → straight to app.
- No network call is required for "login" to succeed.

---

## 2. Feature B — Real profile page reachable from the top-right

**Intent:** today the top-right of the home dashboard has no real account page. Add one.

**Behavior:**
- Add a top-right affordance (avatar/gear/`IconButton`) on the home dashboard (`profile_screen.dart`,
  in the header region near `_ProfileHero`) that pushes a **new `AccountScreen`** (`account_screen.dart`).
- `AccountScreen` renders the current profile from `profileGateProvider.profile`
  (already in memory — no refetch needed on open; optionally refresh via `getProfile`).
- Show: `displayName`, contact (`email`/`phone`), `careRecipient.relationship` + `displayName`, and the
  four `caregiverContext` fields. **Map option `value`s → human labels** via the options payload
  (`getOptions`) — the profile stores raw values like `emotional_burnout`, not labels (R10 note).
- Include a **Log out** action → `logout()` clears `profile_user_id` and returns to `LoginScreen`.
  (This makes the "auth" simulation coherent and is the clean way to re-trigger onboarding.)

**Acceptance:**
- Top-right on the dashboard opens the account page.
- Fields show human-readable labels, not raw option values.
- Log out returns to the login screen and, on next login, a device with cleared identity goes to onboarding.

---

## 3. Feature C — Editable profile (PATCH)

**Intent:** the account page can edit details and persist them.

**Behavior:**
- Add edit affordances on `AccountScreen`: free-text fields (`displayName`, contact,
  `careRecipient.displayName`) and quick-reply/dropdown pickers for the option fields
  (`careRecipient.relationship`, `caregivingDuration`, `primaryCaregivingChallenge`,
  `primarySupportNeed`, `financialStrainSeverity`) sourced from `getOptions`.
- On save, send a **partial** `PATCH /api/profile/<userId>` with only changed fields.
- Reuse the R8/R12 inline error mapping for validation failures (`invalid_email`, `invalid_phone`,
  `required_without_contact`, `invalid_option`, etc.). At least one of email/phone must remain
  (`require_one=True`, see §4).
- On success, update `profileGateProvider` state so the dashboard greeting reflects the new name
  immediately.

**Amends:**
- **R22** ("Profile screen is read-only in v1") → **now editable**.
- **R10** ("Freezed models should cover only create/get/context/options"; "PATCH out of scope") → **add a
  PATCH request model + client method**. `POST /api/profile/resolve` stays out of scope (R9) — do **not** build it.

**Acceptance:**
- Editing a field and saving persists across app relaunch (verify via `getProfile`).
- Clearing both email and phone is rejected inline (not silently).
- Editing a name updates the dashboard greeting without a manual refresh.

---

## 4. Backend facts (already live — no backend changes)

`PATCH /api/profile/<userId>` exists: `backend_v2/profile_routes.py:161` →
`validate_patch_profile` (`backend_v2/profile_validation.py`) → `repository.update_profile`.

**Partial-update contract (confirmed in `validate_patch_profile`):** send only the keys you want to change.
- `userId` in body must equal the path or errors `immutable` — simplest is to **omit `userId`** from the PATCH body.
- Contacts use `require_one=True`: after the patch, at least one of `email`/`phone` must remain non-empty.
- `caregiverContext` accepts: `caregivingDuration`, `primaryCaregivingChallenge`, `primarySupportNeed`,
  `financialStrainSeverity` (option values), plus arrays `secondaryCaregivingChallenges`,
  `secondarySupportNeeds`, `existingSupportNetwork`, and `userAgeRange`.
- `careRecipient` accepts `relationship` (option value) and its text fields.
- Error envelope + codes are identical to create (R10/R12): `{success:false, error:{code,message,fields}}`,
  `validation_error` (400), `contact_already_exists` (409), `profile_not_found` (404).

**Client work:** add to `ProfileApi`:
```dart
Future<UserProfile> updateProfile(String userId, Map<String, dynamic> patch) async {
  final json = await _request(() => _dio.patch('/api/profile/$userId', data: patch));
  return UserProfile.fromJson(json['profile'] as Map<String, dynamic>);
}
```
Reuse the existing `_request` helper (it already maps `profile_not_found` / `validation_error` /
`contact_already_exists` to the typed exceptions).

Wire URL: `PROFILE_API_URL` (default `http://localhost:5002`, already wired via `env_config.dart`, R21).

---

## 5. Non-goals / guards (unchanged from task md)

- No real auth, tokens, OAuth, Firebase/Auth0 — the login is a stub (task md Non-Goals still hold, minus the stub).
- Do not build `POST /api/profile/resolve` (R9) or cross-device identity — identity stays device-local.
- Do not rewrite `ahma_app/.env` (R21) or touch `BACKEND_API_URL`/`:5001` legacy integrations (R3).
- No backend code changes for these three features.
- The 8-question onboarding flow, gate lifecycle, and R11 identity-clear-only-on-`profile_not_found`
  semantics stay as built.

---

## 6. Branch + verification

- Branch: `feat/profile-login-and-editing` off `feat/profile-onboarding`.
- Run the app against the local backend with `ahma_app/dev_setup_and_run.sh` (macOS runner already built).
- Before opening a PR: `cd ahma_app && flutter analyze` must be clean; exercise the full path
  (login → onboarding → dashboard → top-right → account → edit → save → relaunch shows the edit; log out → login).
