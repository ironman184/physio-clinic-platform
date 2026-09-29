# Cliniko

*Simple clinic administration with low-friction patient booking*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 5-6. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

A strong benchmark for a small or growing outpatient clinic that wants appointments, records and billing in one browser-based system. It sells the same core feature set across practitioner-count tiers, rather than reserving basic workflows for expensive plans. This makes it especially useful for studying a focused clinic-management product. [[CL01][CL01], [CL14][CL14]]

### Clinic setup and staff login

The clinic configures locations, practitioners, appointment types and online availability. Each staff member uses a separate login; two-factor authentication can be required. The account-finder flow can email a discovery code, but that is not passwordless patient login: staff still sign into their clinic account with credentials. [[CL04][CL04], [CL05][CL05], [CL06][CL06]]

### New patient and booking journey

The patient opens a hosted booking page or an embedded version on the clinic website, chooses the relevant location, service, practitioner and available time, then enters basic details. No patient account is required for this booking flow. The system can match an existing record or create a new one. The clinic can show practitioner photos, descriptions and booking terms. [[CL03][CL03], [CL04][CL04]]

### Forms and registration

Booking is not the same as completing clinical registration. The clinic can send a secure intake form in a confirmation, reminder or follow-up. Connected form fields update selected patient-record fields; clinical information can have tighter visibility. This separates the short booking transaction from a longer medical-history questionnaire. [[CL11][CL11], [CL12][CL12]]

### Scheduling and recurring treatment

Staff can create daily, weekly, fortnightly or monthly repeats with a chosen interval and number of occurrences. Group appointments have capacity controls; fully booked groups are no longer available online. These are different scheduling objects from one-to-one visits. The public documentation also provides a staff-managed waitlist with patient preferences. [[CL08][CL08], [CL16][CL16], [CL13][CL13]]

### Rescheduling and cancellation

Staff can move an appointment by dragging it or using Reschedule, then confirm the change. The current guide explicitly says patients cannot directly reschedule. Patients can cancel through a message link when the clinic enables it and the notice period allows it. Fully prepaid online bookings have a self-cancellation restriction; deposits are treated differently. [[CL09][CL09], [CL10][CL10]]

## Operations and business

### Notifications

Email and SMS can carry confirmations, reminders, form links and cancellation links. A staff reschedule can trigger an updated confirmation and practitioner notification. Do not confuse the waitlist with an automatic gap-filling engine: Cliniko documents staff filtering and acting on the list, not automatic offers to every matching patient. [[CL09][CL09], [CL11][CL11], [CL13][CL13]]

### Clinical work and money

The product covers treatment notes, patient records, invoices, payments, reporting and telehealth. Its booking system can collect online payments through Stripe. A useful design lesson is that a booked visit, an invoice and a payment are related but different records; paid-booking rules can therefore limit what a patient is allowed to change online. [[CL03][CL03], [CL10][CL10], [CL14][CL14]]

### Website and app design

The patient experience is a short booking form rather than a mandatory account dashboard. Staff work in the browser. The official mobile guide describes adding Cliniko to the phone home screen; that is a browser shortcut, not proof of a separately installed native application. Practitioner photos and service descriptions help patients make the correct booking choice. [[CL03][CL03], [CL04][CL04], [CL07][CL07]]

### Pricing and operating costs

Published USD monthly tiers are $45 for one practitioner, $95 for 2-5, $145 for 6-8, $195 for 9-12, $295 for 13-25 and $395 for 26-200. Administrative users and locations are not separately metered in those tiers. SMS is $0.10 per message; third-party services can add charges. The trial is 30 days. [[CL01][CL01]]

### How it markets and reduces switching friction

The public site emphasizes simplicity, human support, transparent pricing and educational resources. Managed migration is an important part of the offer. However, the self-service import tool is narrower: it is not a general importer for complete notes, appointment and invoice histories. A clinic should distinguish a managed transfer from uploading its own CSV files. [[CL02][CL02], [CL15][CL15]]

### Distinctive lesson and demo checks

The lesson is restraint: make the everyday calendar, records and billing reliable without forcing every patient to create another password. Test a fully prepaid booking versus a deposit booking, cancellation near the cutoff, duplicate-patient matching, and the exact historical data included in migration. For a product requiring patient-led rescheduling, this is a meaningful limitation, not a hidden feature assumption. [[CL03][CL03], [CL09][CL09], [CL10][CL10], [CL15][CL15]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for Cliniko. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-cl01"></a>
**[CL01][CL01]**  Pricing and subscription tiers

<a id="source-cl02"></a>
**[CL02][CL02]**  Product, positioning and learning resources

<a id="source-cl03"></a>
**[CL03][CL03]**  Online booking overview

<a id="source-cl04"></a>
**[CL04][CL04]**  Set up online bookings

<a id="source-cl05"></a>
**[CL05][CL05]**  Staff login and account discovery

<a id="source-cl06"></a>
**[CL06][CL06]**  Two-factor authentication

<a id="source-cl07"></a>
**[CL07][CL07]**  Mobile browser access

<a id="source-cl08"></a>
**[CL08][CL08]**  Repeating appointments

<a id="source-cl09"></a>
**[CL09][CL09]**  Staff rescheduling; patient limitation

<a id="source-cl10"></a>
**[CL10][CL10]**  Patient cancellation rules and prepayments

<a id="source-cl11"></a>
**[CL11][CL11]**  Automatically send patient forms

<a id="source-cl12"></a>
**[CL12][CL12]**  Patient form templates and record updates

<a id="source-cl13"></a>
**[CL13][CL13]**  Waitlist workflow

<a id="source-cl14"></a>
**[CL14][CL14]**  Product feature catalogue

<a id="source-cl15"></a>
**[CL15][CL15]**  Managed migration versus self-service import

<a id="source-cl16"></a>
**[CL16][CL16]**  Group appointments and capacity

[CL01]: https://www.cliniko.com/pricing/
[CL02]: https://www.cliniko.com/
[CL03]: https://help.cliniko.com/en/articles/1023955-a-quick-overview-of-online-bookings
[CL04]: https://help.cliniko.com/en/articles/1023963-set-up-online-bookings
[CL05]: https://help.cliniko.com/en/articles/739411-logging-in-to-cliniko
[CL06]: https://help.cliniko.com/en/articles/1023989-set-up-2-factor-authentication-2fa
[CL07]: https://help.cliniko.com/en/articles/1141545-access-cliniko-on-a-mobile-device
[CL08]: https://help.cliniko.com/en/articles/1777286-book-repeating-appointments
[CL09]: https://help.cliniko.com/en/articles/9492754-reschedule-an-appointment
[CL10]: https://help.cliniko.com/en/articles/1023945-let-patients-cancel-their-appointments
[CL11]: https://help.cliniko.com/en/articles/4447434-automatically-send-forms-to-patients
[CL12]: https://help.cliniko.com/en/articles/3953842-create-patient-form-templates
[CL13]: https://help.cliniko.com/en/articles/1402450-using-the-wait-list
[CL14]: https://www.cliniko.com/features/
[CL15]: https://help.cliniko.com/en/articles/1023899-import-data-from-another-practice-management-system
[CL16]: https://help.cliniko.com/en/articles/9668605-group-appointments-an-overview
