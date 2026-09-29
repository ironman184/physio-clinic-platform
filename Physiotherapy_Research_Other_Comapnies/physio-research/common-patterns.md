# Common patterns and product implications

[Research index](INDEX.md) | [Business comparison](business-and-marketing.md)

> Analysis and unapproved product recommendations. Research snapshot: 25 September 2026. Original report pages: 31-33. This package reorganizes the existing report; vendor facts and prices have not been re-verified.

## How the systems work

The conclusions below are analysis of the documented examples, not a claim that every platform implements the same internal architecture.

### 1. The clinic record comes before the app account

A patient can already exist because reception or a referral created the record. Booking, a portal invitation and mobile-app sign-up are later access paths. Cliniko's guest flow, Jane's linked app accounts and Halaxy's invitations show different solutions. A new system should keep login identity, patient profile, family access and clinical record separate. [[CL03](companies/cliniko.md#source-cl03), [JA06](companies/jane.md#source-ja06), [HA05](companies/halaxy.md#source-ha05)]

### 2. Availability is a set of rules, not empty calendar space

The real question is whether a suitable service can happen with the right practitioner, duration, location and resources. Insurance-heavy products add authorization constraints. Nookal's case/service booking, WebPT's resource rules and splose's cross-location blocking illustrate why a simple free/busy check is insufficient. [[NO08](companies/nookal.md#source-no08), [WE02](companies/webpt.md#source-we02), [SP04](companies/splose.md#source-sp04)]

### 3. A treatment series needs individual exceptions

Physiotherapy often involves a planned series, but staff leave and patient changes affect individual dates. Jane previews conflicts, Zanda asks which part of a series to edit, and Nookal checks recurring dates. The product lesson is to preserve the overall plan while allowing a controlled exception, with a visible audit trail. [[JA08](companies/jane.md#source-ja08), [ZA06](companies/zanda.md#source-za06), [NO08](companies/nookal.md#source-no08)]

### 4. Cancellation is not one database update

A visit can be cancelled while its invoice, payment or package allocation still needs attention. Halaxy makes status affect financial handling; Zanda explains invoice-based package consumption; splose documents manual refund work. Model the appointment status, financial ledger and session entitlement separately, and show their combined result to staff. [[HA10](companies/halaxy.md#source-ha10), [ZA11](companies/zanda.md#source-za11), [SP05](companies/splose.md#source-sp05)]

### 5. Patient freedom is intentionally limited

Self-service rarely means unrestricted editing. The same-therapist/service/location rule in Zanda and splose protects the treatment and price context. Cliniko instead routes rescheduling through staff. Either design can work: the important part is an obvious explanation and a reliable way to contact the clinic when the online action is unavailable. [[ZA05](companies/zanda.md#source-za05), [SP05](companies/splose.md#source-sp05), [CL09](companies/cliniko.md#source-cl09)]

### 6. Communication is an event workflow

Booking, changing, cancelling, arriving, missing a visit and leaving a balance are different events. Recipient preferences, timing and delivery status matter. Zanda's SMS/invoice caveat and splose's duplicate-accounting-reminder warning show that sending a message is not the same as correctly processing the underlying event. [[ZA09](companies/zanda.md#source-za09), [SP10](companies/splose.md#source-sp10), [SP11](companies/splose.md#source-sp11)]

### 7. The staff and patient interfaces should not look identical

Patients need a small set of clear actions. Staff need context, exceptions, work queues and financial consequences. Prompt's task links and operational dashboards, and Halaxy's calendar-led workspace, are two examples of that split. The useful design target is simplicity for each role, not one identical screen for everyone. [[PR04](companies/prompt.md#source-pr04), [PR02](companies/prompt.md#source-pr02), [HA12](companies/halaxy.md#source-ha12)]

## How the businesses compete

### 8. There is more than one market

The clinic-management problem changes with the payer. A small self-pay clinic and a large US rehabilitation group may both need a calendar, but authorization, claims and denial workflows substantially change the product. WebPT and Raintree make those differences clear. A new business should choose its first clinic type and region before copying an enterprise feature list. [[WE02](companies/webpt.md#source-we02), [WE07](companies/webpt.md#source-we07), [RA05](companies/raintree.md#source-ra05)]

### 9. Selling software and finding patients are different jobs

Vendors use education, demos, communities and customer stories to win clinics. Some also sell tools that help clinics win patients: Jane offers website/SEO/review products, Prompt Plus manages leads and follow-up, and Halaxy provides a directory. These are related but separate businesses; a public clinic profile does not establish a functioning marketplace. [[JA02](companies/jane.md#source-ja02), [PR07](companies/prompt.md#source-pr07), [HA01](companies/halaxy.md#source-ha01)]

### 10. Lowering adoption risk is part of the product

Transparent pricing, a trial and migration help reduce the effort of trying new software. Cliniko emphasizes managed transfers; Zanda uses trial and guarantee positioning. But switching out is equally important: TM3's extraction process affects ongoing access. A new vendor can build trust by making both onboarding and departure predictable. [[CL01](companies/cliniko.md#source-cl01), [CL15](companies/cliniko.md#source-cl15), [ZA01](companies/zanda.md#source-za01), [TM15](companies/tm3.md#source-tm15)]

### 11. Monetization follows cost and workflow depth

The sample contains practitioner-count pricing, plan-based feature gates, paid modules and a free-core/paid-usage model. Messaging, payments, claims and AI have separate economic costs. Cliniko, Nookal, Prompt and Halaxy illustrate these approaches. Price comparison should therefore use a complete clinic scenario, not only the cheapest advertised monthly amount. [[CL01](companies/cliniko.md#source-cl01), [NO01](companies/nookal.md#source-no01), [PR07](companies/prompt.md#source-pr07), [HA02](companies/halaxy.md#source-ha02)]

### 12. Integration matters more than feature count

A useful integration carries the right patient, appointment and financial context through the workflow. Exercise prescription, insurer billing, accounting reminders and data migration each have different requirements. Jane's exercise integration, TM3's insurer setup and splose's duplicate-reminder warning show why a long integrations list alone does not prove a smooth experience. [[JA03](companies/jane.md#source-ja03), [TM10](companies/tm3.md#source-tm10), [SP11](companies/splose.md#source-sp11)]

### 13. AI is becoming a layer, not a replacement for sound operations

Prompt and Raintree promote AI across documentation and administration. Some capabilities are current products; others are announcements or future rollout. The underlying appointment, permission and financial rules still need to be correct. Evaluate what the AI may read, suggest and execute, and which actions require a human decision. [[PR09](companies/prompt.md#source-pr09), [RA07](companies/raintree.md#source-ra07), [RA08](companies/raintree.md#source-ra08)]

### Measure the business outcome

For a new product, track activation of clinics, booking completion, no-shows, administrative time per visit, completed follow-ups, money collected and renewal/retention. These are proposed measures, not results established by this research. Measure change against the clinic's own starting point; avoid promising savings based only on vendor testimonials.

## Product implications: recommendations, not requirements

This section is a product recommendation, not a claim about competitor implementation. For a clinic-first app with admin, therapist and patient roles, the strongest opportunity is to make recurring treatment and its exceptions dependable before adding a marketplace or extensive automation.

### First: make one clinic run reliably

Start with patient records, role-based access, the therapist calendar, services and working hours, recurring one-hour treatment plans, attendance, basic notes and a clear payment/session history. Make every cancellation or adjustment record who changed it and why. A therapist should see the right clinical information; an administrator should see the operational work needed to keep the day running.

### Keep the first change workflow controlled

Admin-led rescheduling is a reasonable first version. Allow an administrator to change one visit without unintentionally shifting the remaining series. If patient approval is needed, represent a proposed replacement separately from a confirmed booking, keep the original status clear and send the final confirmation only after acceptance. Avoid silently assigning a different therapist.

### Use phone OTP as access, not as the patient record

A phone-code login may suit your users, but one family can share a number and a patient can change numbers. Keep a durable patient identifier independent of the login method. Add explicit dependent access and a safe recovery process. The number used to receive a code should not itself determine permission to view every linked clinical record.

### Decide the session ledger before drawing the balance screen

Define available, reserved, completed, cancelled-with-credit, cancelled-with-fee and manually adjusted sessions. Decide whether a future appointment reserves a unit and whether a no-show consumes it. Show a readable history explaining each balance change. Do not silently treat a cancelled appointment as a refund or assume a refunded payment always restores a treatment session.

### Then add carefully bounded patient self-service

After the core is stable, add patient booking, forms, confirmations and reminders. Self-rescheduling can begin with a date/time change that keeps the therapist, service and location fixed. Present the notice rule before confirmation and give an obvious contact route when an action is blocked. A patient should never need to guess whether a request is still awaiting approval.

### Delay the expensive second business

A waitlist engine, automated therapist substitution, insurance-heavy billing, AI agents and multi-clinic discovery can follow demonstrated demand. A marketplace requires useful supply, patient trust and acquisition, not merely a search screen. For an initial clinic pilot, better recurring-plan reliability and less receptionist rework are clearer goals than matching all ten platforms feature for feature.

### The strongest overall pattern

The durable product is the system that keeps promises consistent: the patient knows when and with whom treatment will happen; the therapist knows what work is expected; the clinic knows what is owed; and every change reaches the right person. A polished booking page helps, but those connected rules are the core business.
