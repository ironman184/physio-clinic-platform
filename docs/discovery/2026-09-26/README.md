# Physiotherapy platform: foundation review

26 September 2026 · Reviewed snapshot `affb1b73b6d4cf1e4ad5143ad65f4827272b6579` · Whole current codebase, not a release diff

**Recommendation: restart product discovery and redesign the scheduling core before extending the prototype. Preserve the current repository as evidence while deciding the replacement scope. Flutter remains a reasonable candidate; a total rewrite and a new stack are not yet justified decisions.**

The concern is supported by concrete defects, not simply by the fact that AI wrote the code. Equally, this is not a project with no architecture or specification: `specs/scheduling_specs.md` contains a detailed architecture, data model and implementation draft. Its status is **“Draft — pending review.”** Some rules are contradictory, some workflows are only partly wired, and several business decisions were explicitly left unresolved. Implementing that draft more faithfully would reproduce some of the same problems.

No application code, existing specs, supplied research, live records or deployed configuration was changed. This work adds research, review evidence and a local decision map. The supplied research directory was already untracked when the review began.

## Read this in layers

| Document | What it answers |
| --- | --- |
| This overview | What matters, what is proven, and what should happen next |
| [Standards and code audit](standards-and-code-audit.md) | Four heuristic groups; thirteen implementation findings with locations, triggers, confidence and architectural implications |
| [Spec and product audit](spec-and-product-audit.md) | Eight grouped spec findings, twenty-six traceability rows, existing business assumptions and contradictions |
| [Vendor workflow verification](vendor-workflow-verification.md) | Twenty-seven claim assessments from twenty-seven substantive official pages, plus one unreadable URL, across five vendors |
| [Technology options](technology-options.md) | Flutter/Expo/browser choices, Firestore/PostgreSQL trade-offs, a teachable client structure and a contribution-based learning path |
| [Proposed domain and architecture](proposed-domain-and-architecture.md) | Concrete policy alternatives, candidate terminology, module diagrams, command guarantees and acceptance scenarios |
| [Decision map](../../../.scratch/physio-foundations/map.md) | Ten linked decision/research tickets with dependencies; human decisions remain open |

Start with this page. The other reports are supporting evidence and discussion material; they are not a request to read everything before responding.

## What the current system really is

A Flutter client with Firebase phone authentication, one profile per authenticated user, manually established staff roles, three demo clinics, role-specific home screens, and TypeScript Cloud Functions backed by Firestore. Scheduling revolves around a patient/therapist treatment plan, a recurring weekday rule and global slot IDs. Patients and therapists mostly read schedules; administration owns changes.

Good starting ideas include trusted backend scheduling, separate recurrence rules and concrete occurrences, explicit clinic references, reactive authentication, and some separation of models, queries and screens. These ideas can survive a redesign. A default README, a large spec containing implementation code, and the unrelated `approach.md` do not provide a reliable shared product model.

## Standards

The independent Standards review found **zero established violations of documented prose coding standards and four heuristic groups**. The hidden Copilot instruction file is empty, and most actual conventions are tooling configuration. This is not a standards “pass” proving fitness for use.

The four judgment calls are ambiguous primitive state names, duplicated availability decisions, repeated bundles of scheduling identifiers, and appointment/access knowledge scattered through screens and query code. The highest-impact heuristic is `rescheduled` having two incompatible meanings. See the [complete Standards axis](standards-and-code-audit.md#standards-axis--separate-from-correctness).

## Spec

The independent Spec review found **eight grouped findings**: access rules contradict the role matrix; moved appointments remain active; concurrency/retry guarantees are incomplete; date semantics disagree; promised administration flows are unreachable; notification registration is disconnected; renewal is unfinished; and no-show policy remains explicitly undecided. The most severe spec issue is the disagreement between promised role/clinic access and the effective rules. See the [complete Spec axis](spec-and-product-audit.md#spec-axis-summary--eight-grouped-findings).

These axes remain separate. The thirteen implementation findings in the code audit overlap the spec findings; adding their counts would misrepresent the number of independent defects.

## Findings that change the rebuild discussion

| Finding | Concrete consequence | Evidence level |
| --- | --- | --- |
| A user can edit their own `role` and `clinicId`; backend trusts them | A normal authenticated user can satisfy administrator checks if the checked-in rules are deployed | Static rule and source inspection; live rules unknown |
| Commands check the supplied clinic rather than target ownership | A clinic A administrator can mutate a clinic B appointment when given its ID | Original code reproduced with a fake database |
| Availability/idempotency lookup precedes independent writes | Two concurrent requests can create two plans and reserve the same therapist/slot | Static race plus controlled original-code interleaving |
| Old appointments are labelled `rescheduled`, a status also counted as active | A move leaves the previous slot occupied; repeated series moves multiply active records | Original-code reproduction |
| Attendance transitions have no prior-state/idempotency guard | Completing one appointment twice completes a two-visit plan | Original-code reproduction |
| Cancellation and replacement are separate writes | No replacement capacity can produce an error after the original is already cancelled | Original-code reproduction |
| Push delivery is awaited after durable mutations | A communication failure appears to be a failed booking/attendance action; a retry can repeat effects | Original-code reproduction |
| Initialisation, missing UI wiring, time handling and rules/query alignment have further gaps | A feature's file existing does not establish that users can complete its workflow | Source evidence; SDK/runtime qualifications in full report |

The safe interpretation is “the checked-in implementation is not ready for real clinic operation,” not “we observed a production incident.” No live deployment or real patient data was inspected. If the app is already in use, access containment and data preservation become the first operational branch of this work; that status is still awaiting the owner.

## What verification of the company research changed

The provided research is useful and already labels many uncertainties correctly. This investigation rechecked the most decision-relevant subset; it did not verify all 138 original sources or all ten vendors.

- Cliniko explicitly documents that patients cannot self-reschedule. Its online cancellation restrictions distinguish full online payment, deposits and other payment methods. [Staff rescheduling guide](https://help.cliniko.com/en/articles/9492754-reschedule-an-appointment), [patient cancellation guide](https://help.cliniko.com/en/articles/1023945-let-patients-cancel-their-appointments).
- Zanda and splose document restricted patient moves, including keeping practitioner, service and location. This is not equivalent to arbitrary self-service changes. [Zanda](https://zandahealth.com/support/client-portal/reschedule-appointments-on-client-portal/), [splose](https://support.splose.com/en/articles/14117383-allow-your-clients-to-cancel-or-reschedule-their-own-appointments).
- Prompt's own pages still give conflicting answers about patient self-rescheduling. We should retain that uncertainty, not choose the more convenient claim. [EMR product page](https://www.prompthealth.com/products/emr), [scheduling page](https://www.prompthealth.com/features/scheduling).

The product lesson is a reasoned inference: booking, patient change rights, recurrence, financial consequences and clinic exceptions are explicit design choices. Automatic replacement visits, a two-no-show allowance and a thirty-day renewal hold are not established industry norms from the verified evidence.

## The decisions should happen in this order

1. **Customer and outcome:** one clinic, branches, or independent clinics; launch country; real existing records; staff devices; patient access; team skills and operating constraints.
2. **Product and policy:** what a patient can request/confirm, time/resource rules, one-off versus repeated visits, cancellations/no-shows, credits, money, exceptions and communication.
3. **Domain model:** distinguish patient from login, membership from profile, appointment from recurring rule, treatment intent from purchased entitlement.
4. **Architecture:** decide which module owns each invariant, what commits together, how retries and failures behave, and how access is proven.
5. **Technology and low-level design:** compare stack candidates against those constraints, then specify state transitions, schema, command contracts and tests together. Architecture and stack selection may iterate; neither should precede the product assumptions invisibly.
6. **Replacement route:** retain or rebuild each part, preserve any live records, and start a tested end-to-end slice with the owner contributing small, understood changes.

An example makes the levels concrete: “What happens to a prepaid visit after a late cancellation?” is a product question. “Which module owns that effect?” is architecture. “How do the appointment, reservation, entitlement and audit update atomically under duplicate requests?” is low-level design. Choosing Riverpod cannot answer the first or third question.

## My present technology position

Keep Flutter as a candidate if a native mobile app is central. React Native with Expo is a credible alternative; a responsive browser application also deserves consideration if reception work and patient booking links dominate. The owner's existing skills matter more than assuming every app requires Dart. [React Native's framework guidance](https://reactnative.dev/docs/environment-setup).

For a fresh operational system with variable durations, packages and reporting, I would investigate PostgreSQL first because relational constraints and interval exclusion match those needs. Firestore can also support correct booking with an explicit transactional reservation design; it is not ruled out by defects in this implementation. These are conditional engineering recommendations, not accepted decisions. [PostgreSQL range constraints](https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-CONSTRAINT), [Firestore transaction isolation](https://firebase.google.com/docs/firestore/transaction-data-contention).

Prefer a small number of deep modules in one backend deployment initially. Keep screens concerned with presentation and user intent. Place scheduling, permission and entitlement decisions behind trusted interfaces; choose infrastructure only after their guarantees are clear. The detailed alternatives and learning path are in [Technology options](technology-options.md).

## Repair versus replacement

| Situation | Recommended route to discuss |
| --- | --- |
| Prototype only, no live records, and core domain will change | Preserve this snapshot and build a small replacement core alongside it; reuse screens or integration knowledge only after checking fit |
| Live users or records | Contain confirmed access/integrity risks, establish the deployed version and data backup/export, then migrate incrementally with rehearsal and rollback |
| Product stays close to fixed-slot, staff-managed plans | A targeted redesign inside the current stack may cost less than replacing every layer |
| Product requires a different identity/entitlement/time model | Rebuilding that core is more defensible than adding layers over contradictory states and counters |

I lean toward a fresh scheduling/domain core. I do not yet recommend deleting the whole repository or committing to a stack migration. Preserve the current commit, reference screens, source research and useful acceptance examples. Treat existing generated business logic as material to review, not a ready-made foundation. No replacement branch, deletion, migration or deployment has been performed.

## Verification performed and limitations

- Read the current source, six existing spec/review files, relevant supplied research workflows/company sections and official technical documentation.
- Ran eight behavioural probes against original TypeScript function bodies through an in-memory adapter, plus an import-order probe. The primary reviewer reran them successfully. These assert the presence of defects; they are **not eight passing product acceptance tests**. [Script](evidence/scheduling-reproduction.cjs), [output](evidence/scheduling-reproduction-output.txt).
- The adapter does not implement Firebase authentication, real security rules, indexes, SDK input validation, transaction retry/isolation, or production concurrency. Those require integration tests.
- `npm run build` could not execute because `tsc`/installed backend dependencies were absent.
- `flutter test --no-pub` stopped before tests at a sandbox-denied Flutter SDK-cache write. No full Flutter/build pass is claimed.
- No deployment, production records, authenticated vendor flow, purchasing, jurisdiction-specific legal assessment, performance benchmark or cost calculation was performed.
- Local documentation links and decision dependencies were checked. The product/architecture recommendations received an independent consistency review; identity, retry authorization and external-effect qualifications were tightened as a result.

## Continue the discussion

The first unresolved ticket is [Choose the first users and launch scope](../../../.scratch/physio-foundations/issues/01-launch-scope.md). Start with the first customer and country, then clarify whether there are live users/records. We can take the remaining decisions one at a time, using concrete clinic scenarios. No final cancellation policy, architecture, technology stack or rewrite decision has been silently supplied on the owner's behalf.

Review totals: Standards — **0 established documented breaches, 4 heuristic groups**, most consequential: ambiguous appointment state. Spec — **8 grouped findings**, most consequential: access rules contradict the promised role/clinic restrictions.
