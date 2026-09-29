# Raintree

*Enterprise rehabilitation workflows, patient engagement and an expanding AI layer*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 19-20. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

Raintree is an enterprise-oriented rehabilitation platform. Its public materials emphasize coordinated clinical and business workflows across larger organizations; the Ivy Rehab announcement provides a concrete example of enterprise adoption. It is most useful as a benchmark for operating complexity, standardization and scale, rather than as a simple low-cost booking widget. [[RA01][RA01], [RA10][RA10]]

### Staff and patient access

Raintree has a staff sign-in surface and a patient portal. The portal supports appointments, forms, uploads, payments and shared care information. Public product pages do not fully establish the current invitation, password, MFA and recovery sequence for every deployment. That authentication workflow should be demonstrated with both staff and patient roles. [[RA12][RA12], [RA02][RA02]]

### Registration before the first visit

Touchpoints supports self-registration, digital intake and mobile early check-in, with a kiosk option. Patients can provide information and complete administrative steps before seeing the therapist. The portal also handles documents such as insurance uploads. This reduces the separation between registration, the patient record and the day-of-visit workflow. [[RA03][RA03], [RA02][RA02]]

### Appointments and recurring treatment

The official 2023 scheduler training documents block booking with daily, weekly and monthly patterns, start/end dates and provider, case and location context. It also documents restrictions tied to working hours, payer-related settings and authorizations. This is evidence of the underlying scheduling model, not proof that the same screens represent the new 2026 interface. [[RA05][RA05]]

### Rescheduling and cancellations

Staff scheduler training includes changing appointment details and marking visits cancelled or missed. The current public portal page establishes booking capability, but the reviewed evidence does not precisely settle every patient self-reschedule, deadline, package-credit and refund rule. Test these in the actual deployed scheduler and portal, especially when more than one module participates. [[RA05][RA05], [RA02][RA02]]

### Recovering an empty slot

Connect advertises two-way communication and waitlist invitations by text or email. Its gap-filling approach includes first-come-first-served offers, rather than assuming every patient has an exclusive reservation. That changes the patient message and the race-condition behaviour that must be tested when two people accept the same opening. [[RA04][RA04]]

## Operations and business

### Notifications and patient engagement

Connect supports appointment reminders, campaigns, payment-related communication and patient messaging. Its documented workflows include outreach after missed visits and broader announcements. Touchpoints adds registration and check-in tasks. These should be evaluated as one coordinated communication journey so that a patient does not receive contradictory reminders from separate products. [[RA04][RA04], [RA06][RA06], [RA03][RA03]]

### Care, billing and operational work

The portal can share instructions and care-related information, collect outcomes and take payments. Connect adds capabilities including payment plans, stored payment methods, eFax and embedded telehealth. The exact bundle, interfaces and implementation scope need a contract-level check; the existence of a product page does not establish what every subscription includes. [[RA02][RA02], [RA04][RA04]]

### What is new, and what is future

ScribeIQ was launched in 2025. An August 2026 announcement introduced NoteIQ and SchedulerIQ and discussed broader agent-driven workflows. Parts of the prior-authorization, claims, denial and payment-agent roadmap are planned for 2027. Those future items must not be counted as already delivered capabilities on 25 September 2026. [[RA09][RA09], [RA08][RA08]]

### Interface and design interpretation

The older training shows a configurable, information-dense staff scheduler with explicit restrictions and bulk booking. Newer product messaging aims to reduce interaction and manual work through AI-assisted workflows. Compare these surfaces in a live demo: a new marketing concept should not be mistaken for a complete replacement of every existing staff screen. [[RA05][RA05], [RA07][RA07], [RA08][RA08]]

### Marketing, pricing and implementation

Raintree markets through enterprise customer stories, rehabilitation content, webinars and an AI-led product narrative. A dependable current public numeric price was not established. The commercial evaluation should include implementation, data conversion, interfaces, training, support, patient-engagement modules and AI options, not only a monthly license figure. [[RA01][RA01], [RA10][RA10], [RA11][RA11]]

### Strongest lesson and demo checks

Study how the system coordinates many constraints around one treatment episode. Demonstrate an expiring authorization, a recurring series with a one-day exception, two patients accepting one opening, and a failed payment. Ask which AI actions only suggest changes and which can execute them, what approval is required, and which announced components remain on the roadmap. [[RA05][RA05], [RA04][RA04], [RA08][RA08]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for Raintree. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-ra01"></a>
**[RA01][RA01]**  Enterprise rehabilitation product and positioning

<a id="source-ra02"></a>
**[RA02][RA02]**  Patient portal functions

<a id="source-ra03"></a>
**[RA03][RA03]**  Touchpoints: registration and check-in

<a id="source-ra04"></a>
**[RA04][RA04]**  Connect: messaging, waitlists and payments

<a id="source-ra05"></a>
**[RA05][RA05]**  Scheduler restrictions and block booking (PDF) *- 2023 training, not the new UI*

<a id="source-ra06"></a>
**[RA06][RA06]**  Connect workflow overview (PDF) *- 2023 brochure*

<a id="source-ra07"></a>
**[RA07][RA07]**  ScribeIQ and AI product positioning

<a id="source-ra08"></a>
**[RA08][RA08]**  NoteIQ, SchedulerIQ and future agent roadmap *- 20 Aug 2026; some rollout in 2027*

<a id="source-ra09"></a>
**[RA09][RA09]**  ScribeIQ launch *- 2025 announcement*

<a id="source-ra10"></a>
**[RA10][RA10]**  Enterprise adoption: Ivy Rehab

<a id="source-ra11"></a>
**[RA11][RA11]**  Front-office workflow webinar

<a id="source-ra12"></a>
**[RA12][RA12]**  Staff sign-in entry point

[RA01]: https://www.raintreeinc.com/
[RA02]: https://www.raintreeinc.com/patient-portal/
[RA03]: https://www.raintreeinc.com/touchpoints/
[RA04]: https://www.raintreeinc.com/connect/
[RA05]: https://usergroups.raintreeinc.com/UGFiles/Files/04-11-23_RTLive_ManagingSchedulerRestrictions.pdf?_t=1686757092
[RA06]: https://www.raintreeinc.com/wp-content/uploads/2023/10/Raintree-Connect.pdf
[RA07]: https://www.raintreeinc.com/ai/
[RA08]: https://www.raintreeinc.com/blog/raintree_news/raintree-agentic-ai/
[RA09]: https://www.raintreeinc.com/blog/raintree_news/scribeiq-launch/
[RA10]: https://www.raintreeinc.com/blog/raintree_news/ivy-rehab-selects-raintree/
[RA11]: https://landing.raintreeinc.com/spring-clean-your-front-office
[RA12]: https://login.raintreeinc.com/
