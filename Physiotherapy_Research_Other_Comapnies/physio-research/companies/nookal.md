# Nookal

*Case-based allied-health workflows and configurable online booking*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 9-10. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

Nookal is useful for studying clinics where a patient can have different cases, services, funders and appointment types. The product combines scheduling, notes, intake and billing rather than treating each visit as an isolated calendar entry. Its current tiers also separate basic operations from the richer Patient Portal. [[NO01][NO01], [NO03][NO03]]

### Clinic setup and staff access

The clinic defines locations, services or classes, practitioners, working schedules and what is bookable online. Staff sign into Nookal separately from patients. Availability includes recurring working patterns, breaks and leave. The exact staff MFA enforcement and recovery policy should be demonstrated rather than inferred from the existence of a public login page. [[NO05][NO05], [NO11][NO11], [NO14][NO14]]

### Current booking journey

The guide updated on 15 September 2026 describes the new flow, not only the legacy one. A patient starts with location or practitioner, chooses a service or class, then selects a date and time. They enter their details or use an existing Online Booking Code. That code is distinct from a normal portal password. [[NO04][NO04]]

### Payment and new registration

If payment is required, the patient must complete the configured payment step; otherwise the flow can allow booking without immediate payment. Successful bookings produce a confirmation. The clinic can make services, classes and practitioners selectively visible, so online booking is a controlled view of the diary rather than exposure of every empty staff slot. [[NO04][NO04], [NO05][NO05]]

### Optional patient portal login

The Patient Portal is available on Professional and Enterprise. The invitation path lets a patient establish a password, with multi-factor verification through email or SMS. The clinic can add portal-access links to communications. Thus Nookal has two related surfaces: the booking flow using details or a booking code, and a fuller authenticated portal. [[NO06][NO06], [NO07][NO07]]

### Recurring schedules and changes

A staff appointment links the patient to a case and service. Recurring booking requires a date check before saving. Staff can move appointments, update status, cancel with a reason, or cancel and rebook. Recurring-booking tools also manage a series. Patients can cancel via the confirmation link subject to the location rules. Detailed self-rescheduling conditions remain less clearly documented than staff changes. [[NO08][NO08], [NO09][NO09], [NO10][NO10], [NO04][NO04]]

## Operations and business

### Confirmation and reminder system

Confirmation campaigns can be scoped by service or class, location and practitioner, and can include form links. Communication consent and SMS credits matter. Staff should avoid overlapping campaigns that send duplicates. The online-booking flow also supports a clinic message-centre event and optional practitioner notifications, separate from the patient confirmation. [[NO12][NO12], [NO04][NO04]]

### Clinical, financial and operational work

The product offers patient records, clinical notes, invoicing, payments, intake forms and reporting. Case-linked appointments are particularly useful when the same patient has more than one treatment episode. Professional adds capabilities beyond Essentials, while AI and voice functions may require additional paid options. Availability of country-specific claims integrations must be checked regionally. [[NO01][NO01], [NO03][NO03], [NO08][NO08]]

### Website and application design

The public booking flow is configurable rather than fixed: location-first and practitioner-first routes are both documented. The staff help material distinguishes Classic and Fresh interfaces, so training screenshots may not match every account. The clearer design lesson is to keep service, case, practitioner and location visible at booking time, reducing ambiguity later in billing. [[NO04][NO04], [NO08][NO08]]

### Pricing snapshot

The pricing page lists Essentials at USD $65 and Professional at USD $89 per practitioner monthly. It also lists different regional prices, including AUD $49/$59 and GBP 29/39; these are regional tariffs, not exchange-rate conversions. Enterprise is a separate offering. Patient Portal access is not an Essentials feature. Confirm SMS, AI and implementation costs in the actual quote. [[NO01][NO01], [NO06][NO06]]

### How it markets and positions the business

Nookal uses profession-specific pages, demonstrations and educational material to position itself as an allied-health operations system. Its website highlights integrated workflows and newer AI assistance. The sensible interpretation is reduced administrative switching between tasks, not proof that every clinic will achieve a stated time-saving or clinical outcome. [[NO02][NO02], [NO03][NO03]]

### Important boundaries and demo checks

The physical-therapy marketing page advertises simple patient changes, but the inspected help material gives much firmer detail for cancellation than for self-rescheduling. Ask for a live portal demonstration, including a paid recurring visit. Also check export scope and account closure: the cancellation guide requires owner contact and a completed checklist, with processing time before billing stops. [[NO03][NO03], [NO13][NO13]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for Nookal. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-no01"></a>
**[NO01][NO01]**  Regional pricing and plan differences

<a id="source-no02"></a>
**[NO02][NO02]**  Product and positioning

<a id="source-no03"></a>
**[NO03][NO03]**  Physical therapy product page

<a id="source-no04"></a>
**[NO04][NO04]**  New online patient booking flow *- Updated 15 Sep 2026*

<a id="source-no05"></a>
**[NO05][NO05]**  Online booking configuration

<a id="source-no06"></a>
**[NO06][NO06]**  Patient portal setup and authentication

<a id="source-no07"></a>
**[NO07][NO07]**  Patient portal access and invitations

<a id="source-no08"></a>
**[NO08][NO08]**  Staff booking: cases, services and recurrence

<a id="source-no09"></a>
**[NO09][NO09]**  Appointment moves, statuses and cancellation

<a id="source-no10"></a>
**[NO10][NO10]**  Managing recurring bookings

<a id="source-no11"></a>
**[NO11][NO11]**  Staff schedules and working hours

<a id="source-no12"></a>
**[NO12][NO12]**  Confirmation campaigns and forms

<a id="source-no13"></a>
**[NO13][NO13]**  Subscription cancellation procedure

<a id="source-no14"></a>
**[NO14][NO14]**  Staff authentication entry point

[NO01]: https://www.nookal.com/pricing
[NO02]: https://www.nookal.com/
[NO03]: https://www.nookal.com/physical-therapy-software
[NO04]: https://support.nookal.com/hc/en-us/articles/9393534354447-How-Do-Patients-Book-Online
[NO05]: https://support.nookal.com/hc/en-us/articles/9376331799055-How-to-Set-Up-Online-Bookings-in-Nookal
[NO06]: https://support.nookal.com/hc/en-us/articles/17333625058703-How-to-Set-Up-the-Patient-Portal-in-Nookal
[NO07]: https://support.nookal.com/hc/en-us/articles/17098544241551-Giving-Patients-Access-to-the-Patient-Portal
[NO08]: https://support.nookal.com/hc/en-us/articles/13419720249615-Booking-an-Appointment-for-an-Existing-Patient
[NO09]: https://support.nookal.com/hc/en-us/articles/13419900026383-Managing-Appointments
[NO10]: https://support.nookal.com/hc/en-us/articles/9376375242383-Managing-Recurring-Bookings
[NO11]: https://support.nookal.com/hc/en-us/articles/9349315777679-Setting-Up-Staff-Schedules
[NO12]: https://support.nookal.com/hc/en-us/articles/11407478568335-How-to-Set-Up-Appointment-Confirmation-Messages-for-Patients
[NO13]: https://support.nookal.com/hc/en-us/articles/9376330710671-Cancelling-a-Nookal-Subscription
[NO14]: https://login.nookal.com/v3.0/auth/login
