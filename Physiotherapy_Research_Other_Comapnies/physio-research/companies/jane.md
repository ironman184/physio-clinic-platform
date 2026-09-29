# Jane

*Patient portal, mobile experience and clinic-growth tools*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 7-8. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

Jane is a useful benchmark for clinics that care about the full patient experience: finding a service, booking, completing forms, paying and returning for care. Its physiotherapy offering connects clinical documentation with home-exercise support through Physitrack. Regional billing capabilities differ, so a clinic should evaluate its own country rather than assume every integration is global. [[JA02][JA02], [JA03][JA03]]

### Clinic setup and staff authentication

Staff use individual profiles and clinic access permissions. Two-step verification adds a code to the password login, with authenticator and SMS options; phone-call verification has regional limits. Clinics can enforce verification across staff. Treatment definitions, practitioner shifts and online-booking settings determine what patients can actually book. [[JA12][JA12], [JA08][JA08], [JA09][JA09]]

### Patient registration and account structure

Online booking or a clinic welcome email leads into the patient account. The portal stores upcoming and past visits, forms, invoices and other clinic-facing information. The patient mobile app has its own account which is linked to clinic accounts: the app password and an individual clinic password are not automatically the same. This is a significant multi-clinic identity decision. [[JA04][JA04], [JA06][JA06]]

### Booking on the mobile app

The documented path is clinic, discipline or practitioner, treatment, available time and confirmation, with family-member selection when relevant. My Appointments separates upcoming and past visits and supports booking again. The native patient app is documented for Canada and the United States; that should not be presented as worldwide availability. [[JA05][JA05], [JA07][JA07]]

### Recurring appointments and the staff calendar

Staff build a repeated treatment schedule and preview each occurrence against working shifts. The preview distinguishes available dates, conflicts and staff unavailability before the series is saved. Staff can also move or copy visits from the calendar. This is a better model to study than blindly generating the same slot every week. [[JA08][JA08], [JA09][JA09]]

### Patient changes and clinic control

Patients can cancel or reschedule in their account when permitted. Once the clinic cutoff is reached, the action becomes a request to contact the clinic rather than an unrestricted change. The guide also describes a short grace period for a just-created booking. The clinic therefore retains control without making every routine change a receptionist task. [[JA04][JA04]]

## Operations and business

### Reminders, waitlists and communication

Waitlist storage and automatic waitlist notifications are not the same entitlement. The notification tools are limited to Thrive and eligible legacy plans. They match patients to openings and can temporarily hold an offered slot. Jane also documents secure portal messaging; a clinician starts the conversation and the patient can reply. Confirm the appropriate messaging channels for the clinic region. [[JA10][JA10], [JA11][JA11], [JA04][JA04]]

### Clinical and commercial workflow

Intake forms, charting, invoices, payment collection, telehealth and optional insurance workflows sit around the appointment. Physitrack connects exercise prescription with clinical records. Jane also offers AI Scribe, websites, SEO and review tools. These should be treated as a product family with plan and add-on boundaries, not as one all-inclusive subscription. [[JA03][JA03], [JA01][JA01], [JA02][JA02]]

### Interface design worth studying

The patient experience is account-centred: My Appointments, forms and financial history stay together. The mobile app adds a repeat-use surface, while the clinic calendar remains a work tool for staff. Family booking is handled as a deliberate selection, not by treating a shared email address as proof that two people are the same patient. [[JA04][JA04], [JA07][JA07]]

### Pricing snapshot

US monthly starting prices are Balance $54, Practice $79 and Thrive $99. Balance is a small-volume solo plan with a 20-appointment monthly limit; additional practitioner charges apply in the larger plans. AI Scribe is advertised at $15 per opted-in clinician monthly. Insurance and website products add costs; Jane Websites is listed at $59 monthly. [[JA01][JA01]]

### How it markets itself and its customers

Jane uses practitioner-oriented education, webinars, community, ambassadors and customer stories to sell the software. Separately, it sells tools that help a clinic market itself, including websites, SEO and reviews. Those are different acquisition loops: one brings clinics to Jane, the other brings patients to a clinic. [[JA02][JA02]]

### Discovery, limitations and demo checks

Practitioner Search is documented as an early-access beta in British Columbia, not a mature global patient marketplace. Test the separation between app and clinic accounts, parent/child access, cancellation deadlines, waitlist-plan eligibility and local billing support. The most useful lesson is an integrated patient relationship, with explicit regional and commercial boundaries. [[JA13][JA13], [JA05][JA05], [JA06][JA06], [JA10][JA10]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for Jane. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-ja01"></a>
**[JA01][JA01]**  US pricing and optional products

<a id="source-ja02"></a>
**[JA02][JA02]**  Product and clinic-marketing tools

<a id="source-ja03"></a>
**[JA03][JA03]**  Physiotherapy product and exercise integration

<a id="source-ja04"></a>
**[JA04][JA04]**  Patient portal: My Account

<a id="source-ja05"></a>
**[JA05][JA05]**  Patient mobile app: getting started

<a id="source-ja06"></a>
**[JA06][JA06]**  Mobile app: sign-in and linked accounts

<a id="source-ja07"></a>
**[JA07][JA07]**  Mobile app: managing appointments

<a id="source-ja08"></a>
**[JA08][JA08]**  Recurring appointments and conflict preview

<a id="source-ja09"></a>
**[JA09][JA09]**  Staff appointment creation and moving

<a id="source-ja10"></a>
**[JA10][JA10]**  Waitlist notifications: plan restrictions

<a id="source-ja11"></a>
**[JA11][JA11]**  Waitlist notifications: offers and holds

<a id="source-ja12"></a>
**[JA12][JA12]**  Two-step verification for staff

<a id="source-ja13"></a>
**[JA13][JA13]**  Practitioner Search regional availability *- Early-access beta*

[JA01]: https://jane.app/pricing?locale=en-US
[JA02]: https://jane.app/
[JA03]: https://jane.app/physio
[JA04]: https://jane.app/guide/my-account-your-patient-client-portal
[JA05]: https://jane.app/guide/jane-s-mobile-app-for-clients-getting-started
[JA06]: https://jane.app/guide/jane-s-mobile-app-for-patients-signing-in-and-troubleshooting
[JA07]: https://jane.app/guide/jane-s-mobile-app-for-clients-managing-appointments
[JA08]: https://jane.app/guide/recurring-appointments
[JA09]: https://jane.app/guide/chapter-2-appointments
[JA10]: https://jane.app/guide/setting-up-your-wait-list-notifications
[JA11]: https://jane.app/guide/using-wait-list-notifications
[JA12]: https://jane.app/guide/2-step-verification
[JA13]: https://jane.app/guide/when-will-practitioner-search-be-available-in-my-city
