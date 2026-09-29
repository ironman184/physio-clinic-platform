# Technology options for the physiotherapy platform

Date: 26 September 2026. Status: researched options and recommendations, **not an accepted stack decision**.

Read alongside [the current-system audit](standards-and-code-audit.md), [the proposed design](proposed-domain-and-architecture.md), and [the decision map](../../../.scratch/physio-foundations/map.md). Official documentation was checked on the date above. Statements about fit, maintainability, or implementation effort are engineering judgments, not vendor guarantees or benchmarks.

## 1. Flutter is an option, not a constraint

The repository already uses Flutter/Dart for the client and TypeScript for backend scheduling. Keeping Flutter does not mean keeping the current scheduling design. Changing Flutter does not repair backend consistency or authorization.

| Option | When I would shortlist it | What the team would have to learn or prove |
| --- | --- | --- |
| Flutter for the operational application | Native mobile delivery is important and the owner wants to learn Dart; existing screens provide useful experiments | Dart, widgets, asynchronous state, navigation, tests, platform build/release. Verify the actual staff calendar on desktop/tablet, accessibility, keyboard interaction, and phone authentication on each supported target. |
| React Native with Expo | Native mobile is important and the team already understands React/TypeScript, or deliberately chooses that learning investment | React, hooks, TypeScript, native behaviours and release tooling. Sharing a language with the backend does not share all code or remove platform differences. |
| Responsive browser application, optionally installable | Reception staff primarily use laptops/tablets; patients need a booking link or occasional access; app-store distribution has no validated benefit yet | HTML/CSS, browser accessibility, a frontend framework if justified, backend contracts, responsive calendar design. Test target-browser capabilities before promising push or offline behaviour. |
| Separate native Android and iOS clients | Specific platform integrations or an existing specialist team justify independent implementations | Two platform skill sets and release processes. Hard to justify for the currently unvalidated scope. |

React Native's own setup guide recommends a framework such as Expo for new applications. Expo documents a TypeScript tutorial covering Android, iOS, and web, including platform differences. These are credible alternatives; neither source establishes that they are easier for this owner. [React Native setup](https://reactnative.dev/docs/environment-setup), [Expo tutorial](https://docs.expo.dev/tutorial/introduction/).

Installable browser applications are another delivery channel; browser and operating-system support varies, and installation alone does not imply offline functionality. [MDN installation guide](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Making_PWAs_installable).

Flutter's web guidance supports app-like experiences while distinguishing them from text-heavy, search-indexed websites. A clinic operations calendar can be an app-like experience; a public marketing site has different needs. “Flutter web cannot work for admin” would be an unsupported conclusion. [Flutter web FAQ](https://docs.flutter.dev/platform-integration/web/faq).

**My current recommendation:** keep Flutter on the shortlist. Do not choose a replacement because the present code is unsafe. First establish staff devices, patient frequency of use, accessibility expectations, app-store requirements, and the owner's existing language skills. If usage is primarily a receptionist's desktop calendar plus patient links, a browser-first pilot deserves a direct comparison. If mobile is central, evaluate Flutter against Expo with the same small workflow, not two full builds.

## 2. Separate the database choice from the identity and hosting choices

“Firebase or Supabase?” bundles several independent decisions: login provider, database, where trusted code runs, object storage, notifications, and operations. A relational booking database can coexist with an external identity provider. That flexibility has integration cost; do not combine vendors without a concrete reason.

| Criterion | Firestore with trusted backend modules | PostgreSQL with trusted backend modules |
| --- | --- | --- |
| Existing work | Current queries and models already use Firestore | Requires new schema, queries, migrations and possibly data conversion |
| Fixed discrete slots | Transactionally reserve canonical slot documents; every writer must use the same rule | Unique active resource/slot reservations can express exclusivity |
| Arbitrary duration and overlap | Needs an explicit strategy, such as interval occupancy plus resource/day guard documents; crosses days/resources carefully | Range exclusion constraints can express non-overlap for a resource |
| Related clinic records | Deliberate document duplication, application validation, indexes and read projections | Relationships, foreign keys, constraints and transactional writes fit naturally |
| Reporting and credit history | Query design and projections must be planned | Relational reporting and append-only ledgers are a natural fit |
| Offline clients | Decide which cached reads are safe; confirmed reservations still require authoritative coordination | Same product constraint; add offline read support only if needed |
| Main risk | Mistaking a preflight query plus later batch for one atomic decision | Mistaking “SQL” for automatic correctness; constraints, transaction scope and authorization still need design |
| Learning/operations | Firestore access rules, contention, indexes, function lifecycle and observability | SQL, schema migrations, query/index design, connection management, backup/restore and authorization |

Firestore supports serializable transactions. Reads must occur before writes and a transaction callback can be retried. A batch makes its writes atomic but does not protect an earlier availability check performed outside it. The current race is therefore a design defect, not evidence that Firestore cannot implement reliable booking. [Firestore transactions](https://firebase.google.com/docs/firestore/manage-data/transactions), [transaction isolation](https://firebase.google.com/docs/firestore/transaction-data-contention).

PostgreSQL documents range types and exclusion constraints, including a room-reservation example that disallows overlapping time ranges for the same room. Applying this to therapists/resources is a proposed design for our system. It still requires rules for capacity, tenant identity, cancelled reservations, buffers and cross-location staff. [PostgreSQL range constraints](https://www.postgresql.org/docs/current/rangetypes.html#RANGETYPES-CONSTRAINT).

Supabase provides a PostgreSQL database and documents row-level security. It is one managed-hosting candidate; it is not an automatic authorization implementation. Availability of extensions, backup/recovery, region, plan terms and healthcare-related contractual requirements would need checking for the selected launch context. [Supabase database overview](https://supabase.com/docs/guides/database/overview), [row-level security](https://supabase.com/docs/guides/database/postgres/row-level-security).

**My current recommendation:** for a fresh build with variable appointment lengths, packages, invoices, multiple locations and meaningful reporting, investigate PostgreSQL first. For a deliberately constrained fixed-slot pilot, retaining Firestore remains defensible if reservation writes and rules are redesigned and tested. The audit alone cannot choose between them. There is no benchmark or operating-cost measurement in this investigation.

## 3. A small coherent backend before distributed systems

Start the design with one deployable backend containing well-defined modules. A scheduling command should be able to make appointment, resource reservation, entitlement, audit and notification-intent changes together. A worker can deliver communications after that transaction. This is a proposed modular monolith: one deployment, several internal responsibilities.

The current Firebase deployment could host that arrangement; a conventional TypeScript backend with PostgreSQL could also host it. A functions deployment is not inherently a good or bad module design. Microservices would introduce distributed coordination before their independent scaling or team-ownership benefit has been demonstrated.

Firebase recommends idempotent functions: a repeated invocation should not repeat a business effect. For this product, the important unit is the command—create, move, cancel, record attendance—across ambiguous client retries and downstream failures. [Cloud Functions correctness guidance](https://firebase.google.com/docs/functions/tips#write_idempotent_functions).

Do not select queue products, ORM, web framework or cloud plan yet. Evaluate them only after transaction requirements, region, existing skills and operating responsibilities are explicit. Pin supported versions and verify build/deployment compatibility in the selected environment before implementation; this report has not deployed the checked-in version combination.

## 4. If Flutter stays, keep its structure teachable

Flutter's architecture guidance recommends separate UI/data responsibilities, view models, immutable models and dependency injection. It treats a separate domain layer as conditional, and state-management choices as adaptable. A framework recommendation is not a reason to create an extra wrapper around every method. [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations).

Proposed shape, to validate through one workflow:

```text
features/
  appointments/
    appointment_screen.dart        # renders state; sends user intent
    appointment_controller.dart    # loading, errors, selected options
    appointment_models.dart        # data the screen actually needs
    appointment_gateway.dart      # one interface to trusted booking commands
  identity/
  patients/
shared/                            # only things already shared
```

The names are illustrative, not a framework prescription. A client scheduling module should expose behaviours such as “preview a move” and “confirm this move”; screens should not coordinate writes to several collections. Repositories/adapters earn their place when they hide mapping, transport, caching or a real testing seam. Use dependency injection at those seams; avoid global SDK singletons throughout the app.

Choose one state-management convention for new work. The current Provider/Riverpod coexistence is understandable historical migration, not the most serious defect. Riverpod is a candidate because it is already present; it is not an approved requirement or a substitute for separating state from policy.

Keep server-owned rules on the server. A client may preview a policy or improve form validation, but the server must revalidate membership, appointment state, availability and financial implications at commit time.

## 5. How to learn while contributing

Learn around one reliable workflow, with AI explaining and reviewing small changes. Do not ask AI to generate the entire replacement while learning only its screens.

| Stage | Owner's concrete contribution | Evidence of understanding |
| --- | --- | --- |
| Domain first | Write examples of booking, cancellation, no-show and rescheduling in ordinary language | Explain what changes in the calendar, entitlement and money separately |
| Language foundations | Implement small typed values, immutable records and pure policy calculations in the selected language | Explain nullability, collections, errors, dates and async results without relying on copied output |
| One screen | Build a list/calendar detail view against fixed example data | Handle loading, empty, error and stale state; explain where each value comes from |
| One trusted command | Connect a booking or rescheduling action to the backend | Explain why client validation cannot reserve a slot |
| Tests | Add a scenario that fails under duplicate requests or conflicting bookings | Predict the result before running it and explain a failure |
| Operations | Read logs for a failed reminder; restore synthetic data in a test environment | Distinguish saved booking, pending communication and failed delivery |

For Flutter, the official learning pathway covers Dart and Flutter foundations. For Expo, the linked TypeScript tutorial is an introductory exercise, not a clinic-architecture blueprint. [Flutter learning pathway](https://docs.flutter.dev/get-started/learn-flutter), [Expo tutorial](https://docs.expo.dev/tutorial/introduction/).

No calendar-based mastery estimate is justified without knowing current skills and time available. The first learning question is what the owner already knows—JavaScript, Python, Java, C#, SQL, or none—not whether Dart is universally “best.”

## 6. What this research has not decided

- Country, regulatory scope, data residency, legal bases, retention and contractual terms.
- Hosting provider, runtime/framework versions, ORM, queue, notification provider or price.
- Native app versus browser-first delivery.
- Flutter versus React Native versus browser UI.
- PostgreSQL versus Firestore.
- Performance/cost targets or measured team productivity.

These belong to the linked decision map. Recommendations above remain conditional until the owner's answers and, where necessary, a small prototype provide evidence.
