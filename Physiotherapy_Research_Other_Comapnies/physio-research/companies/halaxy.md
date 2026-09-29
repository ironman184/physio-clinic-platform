# Halaxy

*Free-core economics, a patient directory and unusually configurable booking rules*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 21-22. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

Halaxy is a broad practice-management platform with a free core and paid usage-based services. It combines a practitioner directory with clinic operations and a patient portal. It is valuable for studying a different business model from a per-clinician subscription and for understanding how patient discovery and clinic administration can be connected. [[HA01][HA01], [HA02][HA02]]

### Clinic setup and patient acquisition

Online booking is configured per practitioner and location, and the documented setup requires the relevant directory profile to be visible. A clinic can also place booking access on its own website. It can restrict bookings to new or existing patient categories, require approval, and choose whether the patient selects an exact time or requests a broader time period. [[HA03][HA03], [HA04][HA04]]

### Patient records and portal access

The clinic can invite an existing patient into the portal rather than forcing a new patient record to be created. The portal includes appointments, invoices and permitted shared clinical information. Clinics control whether patient-submitted profile changes are automatically accepted, reviewed first or disabled. A portal account and the clinical record are therefore related but separate objects. [[HA05][HA05], [HA06][HA06]]

### Login and security

Halaxy documents email/password access with two-factor options using an authenticator, SMS or email. It also supports passkeys using the device biometric or PIN mechanism, with a fallback sign-in path. Existing-patient booking verification is another, separate step. Do not assume that verifying a phone during booking gives access to every clinical record. [[HA07][HA07], [HA08][HA08], [HA04][HA04]]

### Scheduling and repeat sessions

The booking configuration supports fixed slot intervals or dynamic use of available gaps. Staff create appointments around patient, provider, time, service fee and resources. Repeats can use selected weekdays and an end date or count. The appointment workflow links notes, invoices and reminders, so changing a visit can have consequences beyond the diary. [[HA04][HA04], [HA11][HA11], [HA09][HA09]]

### Patient changes and financial side effects

Patients can use a secure appointment-summary link to cancel or reschedule within the configured rules. Rescheduling creates a new appointment and cancels the old one. The configured cancellation status matters: Cancelled can refund the card payment and zero the invoice; Rejected can retain the balance. This must be tested rather than reduced to a single yes/no cancellation feature. [[HA10][HA10]]

## Operations and business

### Notifications

Halaxy supports email and SMS reminders, confirmations and two-way replies. Settings can be inherited and overridden at patient, practitioner, location and group levels. A patient-specific preference can therefore change what the group default would send. SMS usage is charged in message units; message length matters. Waitlist messaging should not be assumed to be a fully automatic offer engine. [[HA13][HA13], [HA14][HA14]]

### Forms, clinical work and billing

Patient forms can collect consent and update connected record fields. Creating a fee-linked appointment brings invoicing and clinical work into the same workflow. The portal can share selected records and documents rather than exposing the entire internal chart. This is useful for understanding how booking, clinical records and patient access stay connected without becoming identical. [[HA15][HA15], [HA11][HA11], [HA06][HA06]]

### Packages and a different scheduling mode

The online-booking FAQ applies package eligibility to the same service, practitioner and location; a different combination can produce a separate unpaid booking instead. Halaxy also documents express appointments, a virtual-queue workflow for on-demand services. That queue is an alternative scheduling model, not automatically the right design for a clinic offering fixed one-hour treatment sessions. [[HA16][HA16], [HA17][HA17]]

### Website and app design

The staff experience is calendar-led, with a side panel for appointment actions and access to associated patient and financial information. The patient side combines a searchable practitioner directory with booking and portal tasks. This illustrates two separate products to design: the repeat-use clinic workspace and the public route by which someone discovers and books care. [[HA12][HA12], [HA01][HA01], [HA03][HA03]]

### Business model and marketing

The core is advertised as free, while services such as SMS, payment processing, some claiming functions, telehealth and AI can carry charges. The directory is also a patient-acquisition surface. Free software can lower a clinic's adoption barrier, but it does not mean the clinic's total operating cost is zero or that a directory listing guarantees new patients. [[HA02][HA02], [HA01][HA01]]

### Strongest lesson and demo checks

Study configurable policy and identity layers. Test provisional versus confirmed bookings, a paid cancellation under each configured status, a reschedule with linked notes, and a package booked with a different therapist. Check whether directory visibility is acceptable for the clinic. The rich rules are useful, but they increase the need for safe defaults and clear staff explanations. [[HA03][HA03], [HA10][HA10], [HA16][HA16]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for Halaxy. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-ha01"></a>
**[HA01][HA01]**  Product, patient directory and positioning

<a id="source-ha02"></a>
**[HA02][HA02]**  Free core and paid-usage pricing

<a id="source-ha03"></a>
**[HA03][HA03]**  Enable online bookings and directory visibility

<a id="source-ha04"></a>
**[HA04][HA04]**  Booking rules, matching and slot intervals

<a id="source-ha05"></a>
**[HA05][HA05]**  Invite a patient to the portal

<a id="source-ha06"></a>
**[HA06][HA06]**  Patient portal permissions and profile updates

<a id="source-ha07"></a>
**[HA07][HA07]**  Two-factor authentication

<a id="source-ha08"></a>
**[HA08][HA08]**  Passkeys and fallback authentication

<a id="source-ha09"></a>
**[HA09][HA09]**  Repeating appointments and cancellation options

<a id="source-ha10"></a>
**[HA10][HA10]**  Patient changes, replacement visits and refunds

<a id="source-ha11"></a>
**[HA11][HA11]**  Create appointment, fee, invoice and note

<a id="source-ha12"></a>
**[HA12][HA12]**  Calendar-led daily workflow

<a id="source-ha13"></a>
**[HA13][HA13]**  Appointment reminders and reply handling

<a id="source-ha14"></a>
**[HA14][HA14]**  Reminder preference hierarchy

<a id="source-ha15"></a>
**[HA15][HA15]**  Patient forms and record updates

<a id="source-ha16"></a>
**[HA16][HA16]**  Package restrictions in online booking

<a id="source-ha17"></a>
**[HA17][HA17]**  Express appointments and virtual queue

[HA01]: https://www.halaxy.com/
[HA02]: https://www.halaxy.com/pricing
[HA03]: https://support.halaxy.com/hc/en-au/articles/6033494247823-Set-up-online-bookings
[HA04]: https://support.halaxy.com/hc/en-au/articles/6033480868751-Manage-online-booking-preferences
[HA05]: https://support.halaxy.com/hc/en-au/articles/360044499433-Invite-patients-to-the-patient-portal
[HA06]: https://support.halaxy.com/hc/en-au/articles/360044016794-Guide-to-the-Halaxy-patient-portal-for-practitioners
[HA07]: https://support.halaxy.com/hc/en-au/articles/6332462904079-Set-up-two-factor-authentication-2FA
[HA08]: https://support.halaxy.com/hc/en-au/articles/13835520062479-Set-up-passkeys
[HA09]: https://support.halaxy.com/hc/en-au/articles/6033494149263-Set-up-repeat-appointments
[HA10]: https://support.halaxy.com/hc/en-au/articles/6033494173839-Enable-patients-to-cancel-or-reschedule-appointments
[HA11]: https://support.halaxy.com/hc/en-au/articles/6033494038671-Create-a-patient-appointment
[HA12]: https://support.halaxy.com/hc/en-au/articles/6668329666447-The-Halaxy-workflow-for-beginners
[HA13]: https://support.halaxy.com/hc/en-au/articles/6033494392719-Set-up-appointment-reminders
[HA14]: https://support.halaxy.com/hc/en-au/articles/6033481005967-Guide-to-reminder-settings
[HA15]: https://support.halaxy.com/hc/en-au/articles/5178293942927-Set-up-patient-forms
[HA16]: https://support.halaxy.com/hc/en-au/articles/7088837480335-FAQ-Online-Bookings
[HA17]: https://support.halaxy.com/hc/en-au/articles/11824440865679-Guide-to-express-appointments
