# Zanda

*Detailed self-service rules, recurring visits and session-pack accounting*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 11-12. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

Zanda is the renamed Power Diary, not an additional competitor to count separately. It is a useful reference for allied-health clinics needing a calendar, client portal, notes, forms, invoicing and structured packages. Its documentation is unusually explicit about restrictions and financial side effects, making it valuable for product design research. [[ZA02][ZA02], [ZA04][ZA04], [ZA12][ZA12], [ZA14][ZA14]]

### Staff versus patient login

Staff use an email-and-password login with optional two-factor authentication that can be required for the team. Patient portal registration uses an email username and password, followed by verification. SMS verification requires a mobile number; email verification is another option. This is not a phone-number-only, passwordless login model. [[ZA16][ZA16], [ZA13][ZA13], [ZA03][ZA03]]

### Registration and booking

The clinic controls whether new clients can register and whether people can browse before logging in. Registration can match an existing client instead of creating another record. The portal exposes the services or classes made available by the clinic, along with appointments, forms, files and payment-related information. Dependants have a documented portal workflow. [[ZA03][ZA03], [ZA04][ZA04]]

### Recurring appointments

The staff system supports changes to one occurrence, that occurrence and following ones, or the entire recurring set. Changes to a series can rebuild future appointments, so existing invoices and paid visits create important restrictions. A safe workflow must explain the edit scope before saving, rather than silently altering every future session. [[ZA06][ZA06]]

### Patient self-rescheduling

The portal permits eligible future individual appointments to move to a different date or time. The practitioner, service and location stay the same; it is not an unrestricted switch to another therapist. Group visits, booking settings, notice periods and appointment state affect eligibility. A session-pack booking also needs the relevant linked service to be valid. [[ZA05][ZA05]]

### Cancellation and refunds

A portal cancellation does not automatically refund a paid appointment. Paid invoices remain and a refund must be handled separately; unpaid invoice handling is different. Cancellation by SMS has another caveat: it does not automatically delete the invoice. Therefore a clinic must test the portal and SMS routes independently, even though both appear to cancel the visit. [[ZA07][ZA07], [ZA09][ZA09]]

## Operations and business

### Notification behaviour

Zanda supports email and SMS reminders, confirmations and reply processing. Keyword replies can update confirmation or cancellation status. Portal registration, booking, rescheduling and cancellation have configurable client and practitioner notifications. Overlapping global reminders and automation rules can create duplicates, so the configuration is part of the product workflow, not merely a marketing checkbox. [[ZA08][ZA08], [ZA10][ZA10]]

### Packages: the most important accounting detail

Session packs can track sessions, time or money and can carry expiry or referral-related limits. A unit is consumed when allocated to an invoice, not simply when attendance is marked. This is a different model from deducting a session only after treatment. It affects cancellations, future reservations, remaining-session displays and staff explanations to patients. [[ZA11][ZA11], [ZA12][ZA12]]

### Clinical work and operations

Practitioners work from the calendar into client information, notes, forms and files. The documented training includes a Physitrack integration. The wider setup also includes a customizable practice-policy manual and operational tools. These features are relevant to clinic consistency, but a policy template is not a substitute for a clinic reviewing its own procedures. [[ZA14][ZA14], [ZA15][ZA15]]

### Interface design

There are two clear workspaces: a staff calendar for managing the practice, and a client portal for personal actions. Restricting patient rescheduling to the same service, location and practitioner keeps the portal simpler while avoiding a hidden change in price or treatment responsibility. The trade-off is that therapist substitution still needs clinic involvement. [[ZA04][ZA04], [ZA05][ZA05]]

### Business model and marketing

Standard USD pricing starts at $19 monthly for Starter, with its listed restrictions, and $49 for Growth before additional-practitioner charges. Growth adds $19 per additional practitioner; administrative users are not the same billing unit. The site uses a trial, migration support, introductory promotions and a guarantee to lower adoption friction. SMS and other optional services need a separate cost check. [[ZA01][ZA01]]

### Best lesson and demo checks

Study the rules behind the interface, not only the calendar. Demonstrate one changed occurrence in a paid recurring series; cancellation through the portal versus SMS; an expired pack; and restoring a wrongly allocated session. For a new product, write the package ledger and refund policy before deciding what the patient sees as remaining sessions. [[ZA05][ZA05], [ZA06][ZA06], [ZA07][ZA07], [ZA09][ZA09], [ZA11][ZA11]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for Zanda. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-za01"></a>
**[ZA01][ZA01]**  Standard pricing, not introductory promotions

<a id="source-za02"></a>
**[ZA02][ZA02]**  Power Diary becomes Zanda

<a id="source-za03"></a>
**[ZA03][ZA03]**  New-client portal registration and verification

<a id="source-za04"></a>
**[ZA04][ZA04]**  Client portal user guide

<a id="source-za05"></a>
**[ZA05][ZA05]**  Client self-rescheduling restrictions

<a id="source-za06"></a>
**[ZA06][ZA06]**  Recurring appointment edit scopes

<a id="source-za07"></a>
**[ZA07][ZA07]**  Portal cancellations and payment handling

<a id="source-za08"></a>
**[ZA08][ZA08]**  Appointment reminders and reply processing

<a id="source-za09"></a>
**[ZA09][ZA09]**  SMS reminder behaviour and invoice caveat

<a id="source-za10"></a>
**[ZA10][ZA10]**  Portal event notifications

<a id="source-za11"></a>
**[ZA11][ZA11]**  Session-pack expiry and unit consumption

<a id="source-za12"></a>
**[ZA12][ZA12]**  Session packs and budget tracking

<a id="source-za13"></a>
**[ZA13][ZA13]**  Staff two-factor authentication

<a id="source-za14"></a>
**[ZA14][ZA14]**  Practitioner workflow and exercise integration

<a id="source-za15"></a>
**[ZA15][ZA15]**  Practice setup and policy manual

<a id="source-za16"></a>
**[ZA16][ZA16]**  Staff login

[ZA01]: https://zandahealth.com/standard-pricing/
[ZA02]: https://zandahealth.com/blog/powerdiary-now-zanda/
[ZA03]: https://zandahealth.com/support/client-portal/client-portal-registration-for-new-clients/
[ZA04]: https://zandahealth.com/support/client-portal/client-portal-user-manual-for-clients/
[ZA05]: https://zandahealth.com/support/client-portal/reschedule-appointments-on-client-portal/
[ZA06]: https://zandahealth.com/support/appointments-and-reminders/creating-editing-and-deleting-recurring-appointments/
[ZA07]: https://zandahealth.com/support/client-portal/client-portal-appointment-cancellations-and-payments-management/
[ZA08]: https://zandahealth.com/support/appointments-and-reminders/configuring-appointment-reminders/
[ZA09]: https://zandahealth.com/support/appointments-and-reminders/sms-reminders-faqs/
[ZA10]: https://zandahealth.com/support/client-portal/setting-up-and-sending-client-portal-notifications/
[ZA11]: https://zandahealth.com/support/faqs-and-troubleshooting/session-packs-expiry-and-automatic-creation-explained/
[ZA12]: https://zandahealth.com/support/billing-management/using-session-packs/
[ZA13]: https://zandahealth.com/support/account-management/activating-two-factor-authentication/
[ZA14]: https://zandahealth.com/support/practice-administration/training-for-practitioners/
[ZA15]: https://zandahealth.com/support/practice-administration/practice-setup-guide-advanced/
[ZA16]: https://my.zandahealth.com/Account/Login
