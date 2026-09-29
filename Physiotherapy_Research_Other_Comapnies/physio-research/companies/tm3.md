# TM3

*Physiotherapy workflows, referral networks and a newly revised booking journey*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 13-14. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

TM3 belongs to the Blue Zinc product family and is especially useful for studying physiotherapy workflows involving referrals, insurers and structured patient records. Pronto is a related referral-network product, not simply another name for the TM3 diary. Evaluate the combined workflow and its commercial modules rather than assuming everything is part of the base subscription. [[TM01][TM01], [TM10][TM10], [TM11][TM11]]

### Setup and identity

Connect is the patient-facing booking surface. Clinics configure branding, registration permission, online booking limits and provisional approval. Staff have separate account access and password-management help. New Connect documentation shows a magic-link screen in the patient flow; older online-booking guides use an account/password pattern. Do not treat those older screenshots as proof of the current authentication sequence. [[TM02][TM02], [TM04][TM04], [TM16][TM16]]

### New online booking design

The 2026 flow guides patients through the steps relevant to the chosen service. It can show available dates, practitioner and location choices, embedded registration forms and checkout. The guided selector can help distinguish an assessment from follow-up, private payment from insurance, or a referral pathway. The exact steps depend on modules and service configuration. [[TM03][TM03], [TM04][TM04]]

### Linked appointments and recurring availability

Companion booking can require two linked appointments with ordering or timing constraints. Additional services can extend the main appointment or create a separate linked visit. These are not the same as a weekly recurring series. The diary separately supports recurring working availability by practitioner, location and room; the Pronto workflow has a Book Next follow-up action. [[TM03][TM03], [TM12][TM12], [TM11][TM11]]

### Insurance registration

Connect for Insurance can collect insurer, policy number and authorization information before the visit. An important limitation in the patient-journey guide: a submitted pre-authorization code is added as an appointment note, not automatically turned into a formal authorization record. Capturing a number is therefore not equivalent to validating or administering the insurer entitlement. [[TM05][TM05]]

### Rescheduling and cancellation evidence

The older portal guide shows patients cancelling from My Bookings. Current Connect material establishes policy configuration and newer booking features, but does not establish every current self-rescheduling, recurring-edit or refund rule. Require a live demonstration of those actions in the exact Connect version being sold. Do not assume legacy cancellation behaviour applies unchanged. [[TM13][TM13], [TM02][TM02], [TM03][TM03]]

## Operations and business

### Communication and filling openings

TM3 documents scheduled email and SMS reminders, automatic confirmations and configurable sender behaviour. Reply routing changes with the SMS sender option: a branded sender is not necessarily reply-capable. Its Connect guidance also describes waitlist offers with an acceptance window, payment-request links and automated follow-up reminders for unpaid requests. Current charges should be quoted, not copied from older help articles. [[TM07][TM07], [TM08][TM08]]

### Clinical and financial workflow

The client record contains appointments, accounts, documents, authorizations, cases and forms, with actions to add notes and attachments. Healthcode setup connects insurer billing details with the appropriate charges and codes. The Pronto integration connects referral bookings and follow-up appointments with the practice diary. This is a richer workflow than a standalone public booking widget. [[TM09][TM09], [TM10][TM10], [TM11][TM11]]

### Packages and process automation

Connect guidance describes selling packages and handling package credits, alongside subscription payments. The newer booking flow supports available online packages at checkout. Journeys is a separate module for tasks such as referral review and follow-up processes; it must not be assumed to exist in every TM3 account. [[TM08][TM08], [TM04][TM04], [TM03][TM03]]

### Website and app design

The newer interface presents services more clearly, highlights available dates and makes checkout totals easier to review. Clinic branding includes the logo and app icon. The older mobile-app setup guide describes a home-screen shortcut to the Connect website, not evidence of a native app-store application. Staff UI and patient booking UI should be assessed separately. [[TM04][TM04], [TM02][TM02], [TM06][TM06]]

### Marketing and pricing

The public materials sell specialist clinic administration, referral connectivity and guided booking. A particularly concrete growth feature is Google Tag Manager/GA4 support for booking-funnel events, including service selection and failures. This lets a clinic investigate where prospective patients abandon booking. A reliable current public numeric base price was not established; obtain a module-level quote. [[TM01][TM01], [TM14][TM14]]

### Switching risk and strongest lesson

The cancellation/export guide says the extraction process disables software access and produces downloadable data. Plan a sample export and cutover before ending a live account. In the demo, insist on current Connect login, changing one paid visit, refund and package-credit behaviour, and insurer-code handling. The strongest lesson is guided, linked workflows without mistaking captured data for a completed administrative process. [[TM15][TM15], [TM05][TM05]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for TM3. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-tm01"></a>
**[TM01][TM01]**  Blue Zinc product family

<a id="source-tm02"></a>
**[TM02][TM02]**  Connect general settings *- Updated 16 Jul 2025*

<a id="source-tm03"></a>
**[TM03][TM03]**  New Connect flow: what changed *- 8 Jul 2026*

<a id="source-tm04"></a>
**[TM04][TM04]**  Updated Connect flow and magic-link screen

<a id="source-tm05"></a>
**[TM05][TM05]**  Insurance booking patient journey

<a id="source-tm06"></a>
**[TM06][TM06]**  Connect home-screen shortcut *- 2020 guide; not a native app claim*

<a id="source-tm07"></a>
**[TM07][TM07]**  Scheduled email and SMS reminders

<a id="source-tm08"></a>
**[TM08][TM08]**  Waiting lists, payment links and packages

<a id="source-tm09"></a>
**[TM09][TM09]**  Client record and clinical workflow

<a id="source-tm10"></a>
**[TM10][TM10]**  Healthcode billing setup

<a id="source-tm11"></a>
**[TM11][TM11]**  Pronto appointment and follow-up workflow

<a id="source-tm12"></a>
**[TM12][TM12]**  Diary working hours and recurring availability

<a id="source-tm13"></a>
**[TM13][TM13]**  Legacy patient cancellation flow *- 2020; not proof of current Connect rules*

<a id="source-tm14"></a>
**[TM14][TM14]**  Booking-funnel analytics events

<a id="source-tm15"></a>
**[TM15][TM15]**  Subscription cancellation and data extraction

<a id="source-tm16"></a>
**[TM16][TM16]**  Support, password help and release notes

[TM01]: https://www.blue-zinc.com/our-products/
[TM02]: https://help.tm3app.com/en/articles/5554301-connect-general
[TM03]: https://help.tm3app.com/en/articles/15870031-new-connect-booking-flow-what-s-changed
[TM04]: https://help.tm3app.com/en/articles/15886814-connect-updated-booking-flow
[TM05]: https://help.tm3app.com/en/articles/14033968-connect-for-insurance-patient-journey
[TM06]: https://help.tm3app.com/en/articles/4720209-setup-your-connect-mobile-app
[TM07]: https://help.tm3app.com/en/articles/4574944-how-to-set-up-scheduled-email-and-sms-reminders
[TM08]: https://help.tm3app.com/en/articles/6364372-features-that-help-you-manage-your-practice-better
[TM09]: https://help.tm3app.com/en/articles/4552565-client-record-in-detail
[TM10]: https://help.tm3app.com/en/articles/4890880-healthcode-setup
[TM11]: https://help.tm3app.com/en/articles/5657875-how-to-add-appointments
[TM12]: https://help.tm3app.com/en/articles/5578025-ensuring-availability-for-pronto-bookings
[TM13]: https://help.tm3app.com/en/articles/4561380-how-to-cancel-an-appointment-made-online-for-patients-users
[TM14]: https://help.tm3app.com/en/articles/9556518-google-tag-manager-setup-guide
[TM15]: https://help.tm3app.com/en/articles/4585360-cancelling-the-subscription-and-extracting-your-data
[TM16]: https://help.tm3app.com/en/collections/2548764-support
