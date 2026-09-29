# Standards and implementation audit

Reviewed 2026-09-26 against repository HEAD `affb1b73b6d4cf1e4ad5143ad65f4827272b6579`. Scope: the current `physio_clinic_platform` implementation, including Dart screens/models/providers, TypeScript functions, rules, indexes, configuration, and tests. This is a whole-codebase discovery audit, not a review of a user-selected commit range. No application code was changed, and no deployed system or patient data was accessed.

The current code is a useful prototype, but its scheduling and authorization logic needs redesign before real clinic use. These findings do not establish that Flutter or Firebase is inherently unsuitable. Most arise from missing invariants, inconsistent state meaning, and operations split across uncoordinated writes.

## Standards axis — separate from correctness

**Documented-standard violations: none established.** No applicable prose coding standard was found. [The hidden Copilot instructions](../../../physio_clinic_platform/.github/copilot-instructions.md) are empty; [README.md](../../../physio_clinic_platform/README.md) is the generated Flutter introduction. `analysis_options.yaml`, `.eslintrc.js`, and `tsconfig.json` provide tooling rules, which this axis deliberately does not re-report. `approach.md` discusses an unrelated security reverse-engineering workflow and is not a clinic application standard. Absence of documented standards is not evidence of production readiness.

**Four heuristic findings, not hard violations:**

1. **Possible Primitive Obsession / Mysterious Name.** `SessionModel.status` is an unconstrained string (`lib/models/session_model.dart:12`), while `rescheduled` means both historical predecessor and active appointment (`functions/src/scheduling/rescheduleService.ts:42–60`; `availabilityService.ts:65–74`). Give appointment state and change history distinct meanings before choosing types.
2. **Possible Duplicated Code / Repeated Switches.** Availability rules are independently implemented in `checkAvailability` and `findAvailableTherapists` (`availabilityService.ts:26–105, 197–232`), including different ways of selecting a renewal hold. Put the common decision behind one tested interface while retaining efficient data loading.
3. **Possible Data Clumps.** Clinic, patient, therapist, date, slot, and recurrence fields travel as separate strings and dynamic maps (`functions/src/scheduling/sessionService.ts:10–17`; `lib/services/scheduling_service.dart:12–20`; `lib/models/schedule_rule.dart:1–5`). Introduce validated scheduling concepts where they remove caller obligations, not wrappers around every string.
4. **Possible Divergent Change / Shotgun Surgery.** Screens own Firestore queries, format dates, and interpret appointment states, while separate query/provider layers implement similar knowledge (`admin_home_screen.dart:119–124`; `patient_home_screen.dart:91–97`; `session_query_service.dart:14–55`). A state or access-rule change requires edits across screens, queries, and functions. Concentrate those rules behind scheduling and authorized-query interfaces.

Standards-axis total: **0 established documented breaches, 4 heuristic groups**. Highest-impact heuristic: ambiguous appointment state.

## Evidence and limits

- **Static finding:** the checked-in code establishes a problematic path; real deployment behavior has not been tested.
- **Reproduced with an adapter:** original TypeScript function bodies executed through a small in-memory database adapter, with Firebase transport replaced. This demonstrates application control flow, not real Firestore rules, indexes, transaction retries, serialization, SDK validation, or deployment behavior.
- **Environment-dependent concern:** requires the actual SDK/emulator/deployment to establish the exact runtime result.

Eight behavioral probes and one import-order probe are preserved in [the reproduction script](evidence/scheduling-reproduction.cjs), with [captured output](evidence/scheduling-reproduction-output.txt). Run from the workspace root using a recent Node version exposing `node:module.stripTypeScriptTypes`:

```sh
node docs/discovery/2026-09-26/evidence/scheduling-reproduction.cjs
```

The audit used Node `v26.0.0`. There are no installed `functions/node_modules` or application `.dart_tool` dependencies. The root review's `npm run build` could not run because `tsc` was unavailable; `flutter test --no-pub` stopped at a denied Flutter SDK-cache write before executing tests. No complete build, Flutter test suite, Firebase emulator test, or production verification is claimed. The only checked-in Flutter test still asserts the generated counter screen (`test/widget_test.dart:14–28`), which does not describe this application; functions have no test script in `functions/package.json:3–12`.

## Implementation findings

### C1. Critical: users can assign themselves an administrative role

**Evidence:** [firestore.rules:21–27](../../../physio_clinic_platform/firestore.rules) permits a user to create or update their entire own profile. [functions/src/index.ts:41–56](../../../physio_clinic_platform/functions/src/index.ts) trusts that document's `role` and `clinicId` for authorization.

**Trigger:** an authenticated user writes `role: 'admin'` and a chosen `clinicId` to their own user document, then calls a privileged function using that clinic ID. The checked-in rules contain no field allowlist or server-owned membership protection. Setting `patient` in the registration UI does not constrain requests from another client.

**Impact:** administrative privilege and tenant selection are caller-controlled. **Confidence: static, high.** Live rules were not inspected. Put roles and memberships under trusted control; allow patients to edit only explicitly permitted profile fields.

### C2. High: read permissions disclose other users' data

**Evidence:** [firestore.rules:22–25, 43–56](../../../physio_clinic_platform/firestore.rules). Any administrator may read any user document without a clinic comparison. Every clinic member can read all of that clinic's plans, sessions, and renewal holds, without a patient-owner or therapist-assignment condition.

**Trigger:** a patient queries sessions with only their `clinicId`; an administrator reads a user document from another clinic. Both satisfy the checked-in predicates. C1 makes clinic membership itself untrusted, but this excessive access persists independently after C1 is fixed.

**Impact:** patients can retrieve other patients' appointment and treatment-plan metadata; administrators can retrieve cross-clinic profile fields. **Confidence: static, high.** Agree an actor/resource permission matrix and make rules enforce it; screen filtering cannot supply access control.

### C3. High: functions authorize the supplied clinic, not the target object

**Evidence:** [index.ts:268–271, 291–294, 299–327](../../../physio_clinic_platform/functions/src/index.ts); [cancellationService.ts:15–45, 54–87](../../../physio_clinic_platform/functions/src/scheduling/cancellationService.ts); [rescheduleService.ts:15–36, 75–88](../../../physio_clinic_platform/functions/src/scheduling/rescheduleService.ts). The cancellation functions receive `clinicId` but do not compare it with the session/plan. `markSession` likewise does not compare the loaded session's clinic.

**Trigger:** a valid administrator in clinic A supplies `clinicId=A` with a session ID from clinic B. The reproduction executes `markSession` and changes B's session and counters successfully. Knowing or obtaining a target ID is required; C1/C2 make that easier, but this remains an independent defect.

**Impact:** cross-clinic mutation. Full rescheduling can additionally create replacement sessions labeled with the request's clinic rather than the plan's clinic. **Confidence: reproduced with an adapter.** Load and authorize the target and its related objects as part of the command; do not treat a client-provided clinic ID as proof of ownership.

### C4. High: booking and idempotency are vulnerable to concurrent requests

**Evidence:** [index.ts:85–95, 125–169](../../../physio_clinic_platform/functions/src/index.ts); [availabilityService.ts:65–74](../../../physio_clinic_platform/functions/src/scheduling/availabilityService.ts); [sessionService.ts:23–45](../../../physio_clinic_platform/functions/src/scheduling/sessionService.ts). Reads test availability and idempotency, then separate writes create randomly named plans/sessions. No shared resource reservation or transactional idempotency record coordinates competing commands.

**Trigger:** two simultaneous `createPlan` requests for the same therapist/date/slot both read an empty result before either writes. The adapter reproduction supplies the *same* idempotency key and gets two plans and two occupied records for the same slot.

**Impact:** double bookings and duplicate plans. Extensions and moves use the same check-then-write pattern. **Confidence: application interleaving reproduced; real Firestore concurrency not tested.** Treat availability as advisory until an atomic booking command claims a shared resource. Reserve the idempotency key atomically with its result; preserve that key across user retries (`create_plan_screen.dart:94–106` currently creates a new UUID each invocation).

### C5. High: rescheduling leaves the old appointment active and can multiply visits

**Evidence:** [rescheduleService.ts:26–60, 83–108, 158–167](../../../physio_clinic_platform/functions/src/scheduling/rescheduleService.ts); [availabilityService.ts:65–74](../../../physio_clinic_platform/functions/src/scheduling/availabilityService.ts); [session_model.dart:86–88](../../../physio_clinic_platform/lib/models/session_model.dart).

**Trigger:** move a future appointment from Monday to Tuesday. The old record becomes `rescheduled`, and a new `scheduled` record is inserted. Availability, calendars, modification controls, and full rescheduling all treat both statuses as active. Moving the original again succeeds. The reproductions show three active records after moving the original twice; two full reschedules turn one appointment into four active records.

**Impact:** the old slot never becomes available; phantom visits remain visible; repeated moves inflate work and may distort completion accounting. **Confidence: reproduced with an adapter.** Decide whether a move updates the current appointment or supersedes an immutable occurrence. Either way, distinguish history from occupied capacity and count only current occurrences.

### C6. High: attendance transitions are not idempotent and do not validate previous state

**Evidence:** [index.ts:310–355, 357–369](../../../physio_clinic_platform/functions/src/index.ts). The transaction reads the plan before writing, so this is **not** a Firestore read-after-write error. It reads the session outside the transaction and never validates the existing status, date, or a command key.

**Trigger:** call `markSession(..., completed)` twice for one appointment. Each increments `completedSessions`; the reproduction completes a two-session plan after counting the same appointment twice. Changing an already completed appointment to `no_show` also increments absence accounting without reversing completion.

**Impact:** premature plan completion, repeated holds, duplicate replacement visits, inconsistent counters. **Confidence: duplicate completion reproduced with an adapter; related transitions static.** Validate and record the transition atomically with affected balances; make repeat delivery return the previous result.

### C7. High: commands can report failure after leaving durable partial changes

**Evidence:** [cancellationService.ts:31–45, 89–110, 211–227](../../../physio_clinic_platform/functions/src/scheduling/cancellationService.ts); [rescheduleService.ts:95–155](../../../physio_clinic_platform/functions/src/scheduling/rescheduleService.ts); [index.ts:146–179](../../../physio_clinic_platform/functions/src/index.ts).

**Trigger:** cancel a future session when no replacement slot can be found. Cancellation and the counter update commit before replacement search fails. The reproduction returns an error but leaves the original cancelled, the counter incremented, and no replacement. A plan may similarly be saved before session creation fails; retrying with its existing key then returns that incomplete plan as a duplicate. Full rescheduling modifies all old records before validating replacement availability.

**Impact:** an error message does not mean nothing changed, and retries cannot reliably repair the operation. **Confidence: cancellation failure reproduced; other failure windows static.** For bounded changes, validate and commit a complete transition atomically. For deliberately multi-step operations, expose a durable operation state with repair/retry semantics rather than pretending the operation is one atomic call.

### C8. High: replacement generation can schedule into the past and ignores allowance exhaustion

**Evidence:** [cancellationService.ts:146–164, 180–219](../../../physio_clinic_platform/functions/src/scheduling/cancellationService.ts); [index.ts:349–352, 367–369](../../../physio_clinic_platform/functions/src/index.ts).

**Trigger:** mark the last outstanding visit as a no-show, with no `scheduled`, `rescheduled`, or `completed` record left. Extension falls back to the original `scheduleRule.day1`, rather than a future planning floor. The reproduction uses a historical plan start and creates a replacement in 2020. With `remainingNoShows=0`, the same command decrements it to `-1` and still schedules a replacement.

**Impact:** historical replacement appointments and a nominal allowance that does not constrain behavior. **Confidence: reproduced with an adapter.** Scheduling into the past is a concrete error for this automatic-replacement flow. The correct treatment when an allowance is exhausted remains a product decision; zero must not silently behave like an unlimited replacement entitlement unless that is explicitly the agreed policy.

### C9. High: the plan-details query is incompatible with the checked-in rules

**Evidence:** [session_query_service.dart:46–55](../../../physio_clinic_platform/lib/services/session_query_service.dart) filters by `planId` only; [firestore.rules:49–51](../../../physio_clinic_platform/firestore.rules) requires the session's `clinicId` to match the caller's clinic. [plan_detail_screen.dart:19–26](../../../physio_clinic_platform/lib/screens/admin/plan_detail_screen.dart) displays this stream.

**Trigger:** open a plan's details with the checked-in rules deployed. The query does not establish the clinic constraint for its potential result set, so it is denied even if the actual sessions all belong to the administrator's clinic. This is an inference from code and [Firebase's documented query/rule semantics](https://firebase.google.com/docs/firestore/security/rules-query), not an emulator execution.

**Impact:** plan details and its session actions cannot load under this ruleset. **Confidence: static plus official documentation, high.** Design authorized queries and read permissions together; including an opaque plan ID does not implicitly prove clinic ownership.

### C10. Medium: the UI and backend disagree about same-day modification

**Evidence:** [session_model.dart:78–88](../../../physio_clinic_platform/lib/models/session_model.dart) marks today as modifiable; [cancellationService.ts:22–28](../../../physio_clinic_platform/functions/src/scheduling/cancellationService.ts) and [rescheduleService.ts:21–27](../../../physio_clinic_platform/functions/src/scheduling/rescheduleService.ts) reject `date <= today`. Dart uses device-local dates while TypeScript uses UTC dates.

**Trigger:** on the same calendar date, select Cancel or Reschedule for an appointment shown as modifiable. The server rejects it as a past appointment. Near midnight, device and server can disagree about which day is today. No slot start time or clinic time zone participates in the decision.

**Impact:** controls promise an action that cannot succeed, and policy changes implicitly at UTC midnight. **Confidence: static, high.** Choose a clinic-local instant-based policy and use its eligibility result in the UI. Also distinguish attendance marking eligibility from cancellation eligibility; past appointments currently lose the shared action menu altogether (`plan_detail_screen.dart:186–205`).

### C11. High: module initialization requests Firestore before Admin SDK initialization

**Evidence:** [index.ts:8–22](../../../physio_clinic_platform/functions/src/index.ts) imports scheduling modules before calling `admin.initializeApp()`. Those modules execute `admin.firestore()` at module scope, for example [availabilityService.ts:1–4](../../../physio_clinic_platform/functions/src/scheduling/availabilityService.ts).

**Trigger:** load the functions entry point in a fresh process without an already initialized default Firebase app. Imported module bodies execute first. The import-order probe confirms that Firestore is requested before initialization, using a stand-in that enforces that precondition. [Firebase's Admin setup documentation](https://firebase.google.com/docs/admin/setup) initializes the default app before accessing its modules.

**Impact:** expected cold-load/deployment-discovery failure. **Confidence: static import-order evidence; actual installed SDK execution remains unverified because dependencies are absent.** Initialize shared infrastructure in one composition module before accessing it, or inject initialized dependencies into the scheduling implementation.

### C12. Medium: notifications are disconnected and can turn successful commands into apparent failures

**Evidence:** [notification_service.dart:12–40](../../../physio_clinic_platform/lib/services/notification_service.dart) defines token registration/removal, but repository search found no caller of that module. [auth_provider.dart:116–120](../../../physio_clinic_platform/lib/providers/auth_provider.dart) signs out without token removal. Functions await push delivery after mutation, for example [index.ts:357–379](../../../physio_clinic_platform/functions/src/index.ts).

**Trigger:** a new installation signs in through the actual application: there is no path calling notification initialization. Separately, seed a valid token and make FCM fail during completion: the reproduced command throws after status/counters have already committed.

**Impact:** notifications are not end-to-end wired, and delivery failures invite duplicate command retries. **Confidence: missing calls static; post-commit failure reproduced with an adapter.** Persist a notification intent with the business change and deliver it independently, with retry/deduplication and explicit token lifecycle handling. The TypeScript stale-token cleanup also passes one array to a variadic element operation (`notificationService.ts:85–91`); compare the [Node array-operation examples](https://firebase.google.com/docs/firestore/manage-data/add-data). Validate this path with the real SDK before release.

### C13. Medium: availability ignores additional renewal holds

**Evidence:** [availabilityService.ts:80–101, 183–195, 222–230](../../../physio_clinic_platform/functions/src/scheduling/availabilityService.ts). The single-date check uses `.limit(1)` for all holds on a therapist/slot. The bulk check stores only one hold per therapist in a map, overwriting earlier ones.

**Trigger:** therapist T has a Monday hold for patient A and a Tuesday hold for patient B at the same time slot. A single-date Tuesday check may inspect only A's hold and report Tuesday free. The bulk path may overwrite A with B and report Monday free. Checking one matching-patient hold can also bypass a different patient's hold.

**Impact:** preview and booking may disagree or permit a slot still reserved for someone else. **Confidence: static, high.** Evaluate all relevant holds, or encode a uniqueness constraint that genuinely makes one hold sufficient. No such invariant is enforced by the current creation code (`renewalService.ts:19–30`).

## Additional gaps to investigate, not established production incidents

- **Input contracts are partial.** `index.ts:79–83` tests required values for truthiness rather than positive integer counts or valid memberships. `createPlan` does not verify that the patient exists, that patient and therapist belong to the clinic, or that they have the expected active roles. `validators.ts:7–37` does not reconcile frequency with selected weekdays. Reschedule paths bypass that validator altogether. UI validation cannot define the trusted contract.
- **Patient and resource conflicts are not modeled.** Availability checks only therapist + date + exact `slotId`; they do not detect overlapping time ranges, the same patient booked with another therapist, room/equipment capacity, leave, or temporary closures. Whether all are MVP requirements must be decided; the current interface cannot promise these protections.
- **Deployment is not reproducible from these files alone.** `firebase.json` has no Firestore rules/indexes mapping or emulator configuration. `firestore.indexes.json` does not document every composite query shape present in the code; deployed indexes and automatic index merging need verification before naming any particular runtime index failure. No live configuration was accessed.
- **Error presentation can hide failures as empty data.** Several home-screen stream builders read `snapshot.data?.docs ?? []` without handling `hasError`, for example `admin_home_screen.dart:125–133` and `patient_home_screen.dart:98–106`. A permission/index/network failure can be shown as no appointments/plans. `main.dart:103–108` instead shows a permanent loader on a profile-stream error.
- **Availability search state can become stale.** `_TherapistList` loads only in `initState` (`create_plan_screen.dart:542–580`), with no `didUpdateWidget` refresh when retained form state changes. Exact impact depends on PageView lifecycle and merits a widget-level reproduction.
- **Provisioning and operational recovery are not implemented as product flows.** Slots and availability are client-read-only; the exported functions do not supply clinic setup, staff invitation, availability maintenance, or recovery/reconciliation commands. Prototype data may have been created manually. Existing document IDs are not an onboarding process.

## Architecture observations and deep-module opportunities

The repository already separates screens, models, providers, query wrappers, and scheduling functions. The weakness is what those interfaces guarantee. Callers must know too much about document fields, status strings, write ordering, clinic scope, and retry behavior. Adding more folders or a generic repository interface will not repair that.

| Candidate deep module | Small interface and guarantees | Complexity kept inside |
|---|---|---|
| Identity and clinic membership | Resolve an actor's trusted memberships and authorize an action on a loaded resource | Invitation/bootstrap rules, roles, disabled users, clinic scope, patient ownership, therapist assignment |
| Scheduling | Preview a proposal; book, move, cancel, or record attendance with an operation ID and expected version; return a committed result or a defined conflict | Resource conflicts, recurrence expansion, occupancy, state transitions, atomicity, retries, history, concurrent edits |
| Treatment entitlements | Explain a balance and apply an agreed policy outcome once | Purchased/delivered/forfeited/replacement visits, reversals, package expiry, separation of appointment history from entitlement |
| Policy evaluation | Given appointment facts, actor, clinic time, and a policy version, return eligibility and consequences | Deadlines, reasons, cancellation/no-show distinctions, exceptions, override permissions; pure decisions without hidden writes |
| Notification delivery | Accept a committed notification intent and report delivery state | Provider calls, device tokens, retries, deduplication, delivery logs; failures do not reverse appointment truth |
| Authorized schedule queries | Return the caller's permitted daily schedule, patient agenda, or plan history | Database query/index details, tenant/owner constraints, pagination, current-versus-historical appointment projection |

These are candidate modules in one deployable application, not a recommendation for six microservices. Start with the scheduling and membership seams because current defects concentrate there. Keep persistence and notification adapters internal where possible. A production database plus a local emulator/test database is a justified seam; a generic abstraction with one hypothetical implementation is not.

The scheduling interface should hide the hard guarantees, not merely rename seven Cloud Functions. A useful command result answers: what changed, whether it was committed, which appointment version is current, what conflicts prevented the change, and whether a retry is the same operation. The caller should not orchestrate “update old session, adjust counters, create replacement, notify.”

Model an **appointment occurrence**, a **recurring series**, a **treatment course**, and a **paid entitlement/package** separately if the clinic actually distinguishes them. Today `totalSessions` is both an initial target and a counter increased when cancellations/no-shows create replacements (`cancellationService.ts:222–227`). That can be internally consistent for one narrow convention but is not a clear commercial or clinical concept. Product discovery must settle that meaning before a schema is finalized.

## What to preserve and what to replace

Preserve the repository and its history as an executable record of the prototype. Useful assets include the phone-auth flow, role-specific screen sketches, recurrence examples, candidate-date calculation, and a compact list of currently imagined workflows. They still need review and tests; reuse is not certification.

Rework the trusted membership model, scheduling state machine, booking concurrency, idempotency, and appointment/entitlement accounting before adapting screens around them. Notification delivery should follow a committed scheduling result. The current runtime test surface should be replaced with scenario tests across these module interfaces, plus real database/rules integration tests for permissions and races.

The decisive acceptance scenarios are concrete: two receptionists compete for the same slot; one user retries after a lost response; a move frees its original capacity; a failed move preserves its prior booking; a patient cannot read another patient's appointment; another clinic's IDs cannot be mutated; attendance is counted once; a cancellation policy uses clinic time; and notification outage does not change booking truth. The preserved adapter probes identify where the current implementation fails several of these scenarios; they are not substitutes for the eventual integration tests.
