# splose

*Modern allied-health workflows, funded-care operations and restricted patient self-service*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 23-24. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

splose is an allied-health platform that emphasizes connected clinical work, scheduling and funded-care administration. It is useful for studying a modern clinic workspace where billable work includes both patient appointments and support activities. Its public materials also highlight AI assistance, forms, reporting and exercise-system integration. [[SP01][SP01], [SP06][SP06]]

### Staff onboarding and authentication

Practitioner setup includes an invited workspace account, access permissions, services and availability. The current security guide requires staff two-factor authentication; an SSO workspace follows its identity-provider arrangement. These are staff controls, not evidence that every patient must create the same sort of account before using an appointment link. [[SP12][SP12], [SP13][SP13]]

### Patient booking and registration surface

The updated booking system supports multiple branded pages with location, service and practitioner filters, a next-available option and waiting-list access. Clinics choose photos, logos, notices and policies. This public booking surface is distinct from staff login. The reviewed guides establish booking and message-link actions, but not a universal native patient-app login workflow. [[SP04][SP04], [SP05][SP05]]

### Scheduling and recurring work

Staff can create appointments with service, location, case and other details, including recurrence. Working availability supports repeated and one-off patterns. Cross-location busy time can block online availability elsewhere. The system also distinguishes an appointment from a support activity such as report writing: support activity does not send the patient an appointment notification. [[SP06][SP06], [SP07][SP07], [SP04][SP04]]

### Patient rescheduling

Self-rescheduling requires the updated online-booking system. Patients use the link in a confirmation or reminder and can change date and time, but not the practitioner, service or location. A price change since the original booking can block self-rescheduling and require clinic help. This is a deliberately limited operation, not a full replacement of the appointment. [[SP05][SP05]]

### Cancellation and appointment status

The clinic configures notice periods, reasons and fee rules, including calendar-day or business-day handling where relevant. Arrival, cancellation and did-not-attend are distinct statuses. Self-cancellation of a paid appointment does not automatically refund it; financial handling needs staff action. Status changes and money movements therefore need separate checks. [[SP09][SP09], [SP08][SP08], [SP05][SP05]]

## Operations and business

### Notifications and financial follow-up

Email and SMS templates cover confirmations, reminders, rescheduling and cancellations, with service-specific settings. Invoice reminders are separately configured and can target approaching or overdue balances. The guide warns about duplicate reminders when accounting software also sends them. Consent, correct contact details, time zone and available SMS credits affect what is actually delivered. [[SP10][SP10], [SP11][SP11]]

### Clinical and billing workflow

The product supports notes, forms, cases, reporting and integrations, including Physitrack in its public product materials. The distinction between face-to-face appointments and support activities matters for funded-care clinics. A cancellation fee is also not simply a checkbox: the reason, timing and invoice treatment have their own rules. [[SP01][SP01], [SP06][SP06], [SP09][SP09]]

### Prepayment detail worth testing

The documented self-service workflow treats prepayment as credit associated with a draft invoice, with arrival helping finalize and apply it. A cancellation or a visit not marked arrived can therefore need manual financial handling. Check this alongside the prohibition on automatic refunds rather than assuming payment, booking and attendance always change together. [[SP05][SP05]]

### Interface and marketing

Branded, filterable booking pages provide a patient-friendly front end; the staff side focuses on calendar, service and case context. The public website combines an allied-health focus with an AI-forward message, trial access and educational resources. The most useful design pattern is clear separation of the patient's simple action from the clinic's more detailed operational record. [[SP04][SP04], [SP06][SP06], [SP01][SP01], [SP02][SP02]]

### Pricing: current versus announced

Australian monthly pricing is AUD $30 per practitioner, excluding GST, with an annual-plan monthly equivalent of AUD $27. An official September announcement increases these to AUD $36 and $32 for new sign-ups and renewals from 1 November 2026. These future prices are not the current September price. SMS, payments and AI costs require separate consideration. [[SP02][SP02], [SP03][SP03]]

### Roadmap boundary and demo checks

The September update lists class-booking and package improvements among forthcoming work. Do not count that roadmap as already delivered or confuse an existing group appointment with a complete class-membership system. Test a changed service price, paid cancellation, cross-location therapist conflict and cancelled funded visit. The strongest lesson is precise self-service boundaries around a connected clinical and billing record. [[SP03][SP03], [SP04][SP04], [SP05][SP05], [SP09][SP09]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for splose. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-sp01"></a>
**[SP01][SP01]**  Product, funded-care workflows and integrations

<a id="source-sp02"></a>
**[SP02][SP02]**  Pricing and trial

<a id="source-sp03"></a>
**[SP03][SP03]**  2026 price change and future feature roadmap *- 17 Sep 2026; prices change 1 Nov*

<a id="source-sp04"></a>
**[SP04][SP04]**  Updated online booking pages

<a id="source-sp05"></a>
**[SP05][SP05]**  Client self-change, payment and price restrictions

<a id="source-sp06"></a>
**[SP06][SP06]**  Staff appointment creation and rescheduling

<a id="source-sp07"></a>
**[SP07][SP07]**  Recurring working availability

<a id="source-sp08"></a>
**[SP08][SP08]**  Appointment statuses

<a id="source-sp09"></a>
**[SP09][SP09]**  Cancellation reasons, notice and fees

<a id="source-sp10"></a>
**[SP10][SP10]**  Appointment communication templates

<a id="source-sp11"></a>
**[SP11][SP11]**  Invoice reminders and accounting duplicates

<a id="source-sp12"></a>
**[SP12][SP12]**  Required staff two-factor authentication

<a id="source-sp13"></a>
**[SP13][SP13]**  Practitioner onboarding and access

[SP01]: https://splose.com/
[SP02]: https://splose.com/pricing
[SP03]: https://splose.com/resources/the-handover/splose-2026-pricing-update
[SP04]: https://support.splose.com/en/articles/11742846-set-up-online-bookings-updated
[SP05]: https://support.splose.com/en/articles/14117383-allow-your-clients-to-cancel-or-reschedule-their-own-appointments
[SP06]: https://support.splose.com/en/articles/4737776-create-and-reschedule-an-appointment
[SP07]: https://support.splose.com/en/articles/4736435-set-up-your-availability
[SP08]: https://support.splose.com/en/articles/4455180-update-the-status-of-an-appointment
[SP09]: https://support.splose.com/en/articles/4736419-set-up-cancellation-reasons-and-rules-for-appointments
[SP10]: https://support.splose.com/en/articles/4737696-set-up-appointment-templates-and-reminders
[SP11]: https://support.splose.com/en/articles/8635978-set-up-invoice-reminders
[SP12]: https://support.splose.com/en/articles/4737628-set-up-two-factor-authentication
[SP13]: https://support.splose.com/en/articles/15498655-getting-started-as-a-practitioner
