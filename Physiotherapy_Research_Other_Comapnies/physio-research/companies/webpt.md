# WebPT

*US rehabilitation operations, authorization tracking and billing depth*

[Research index](../INDEX.md) | [Platform overview](../overview.md)

> Reference research. Research snapshot: 25 September 2026. Original report pages: 15-16. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Patient and scheduling workflow

### Where it fits

WebPT is a rehabilitation-focused system to study when the clinic must coordinate clinical documentation, scheduling, insurance billing and patient engagement. It is particularly relevant to US outpatient workflows. Its value proposition is broader than a calendar: payer rules, authorization limits and the financial follow-through of a visit are central to the product. [[WE01][WE01], [WE02][WE02], [WE07][WE07]]

### Staff and patient access

WebPT exposes different product login entry points rather than one universal staff-and-patient account. Its patient-relationship-management login can use WebPT credentials for WebPT customers. Digital intake and the home-exercise patient app are separate patient-facing surfaces. The reviewed public material does not establish one common patient password or MFA process for every module. [[WE09][WE09], [WE10][WE10], [WE03][WE03], [WE08][WE08]]

### New patient registration

Digital intake collects registration, consent and policy information before the first evaluation and places the information into the clinical workflow. The clinic can customize fields and branding. This is important because a patient may initially arrive through a phone call, referral or booking request; self-creating a portal account is not the only registration path. [[WE03][WE03]]

### Online booking versus a request

WebPT describes publishing appointment availability through links on websites and other channels. The inspected scheduling guidance also describes a staff queue where online requests are reviewed and confirmed. Therefore the safe interpretation is a configurable request-and-confirm workflow, not proof that every online selection immediately becomes a confirmed appointment. Ask the sales team to show the configuration. [[WE04][WE04], [WE05][WE05]]

### Scheduling rules

The scheduling product covers providers, patients, rooms, equipment and locations. It tracks remaining authorized visits or units and authorization expiry, and supports staff appointment moves. This matters for a treatment series: a clinically suitable free slot may still be unsuitable because the payer authorization, resource or other administrative requirement does not fit. [[WE02][WE02]]

### Recurring visits and patient changes

The public sources establish staff scheduling and rescheduling, but do not show enough detail to specify all recurring-series edit scopes or patient self-cancellation conditions. For a physiotherapy evaluation, test a multi-week plan, one therapist absence, an authorization expiry mid-series, a late cancellation and a patient-requested move. These remain demonstration requirements rather than asserted automatic capabilities. [[WE02][WE02], [WE04][WE04]]

## Operations and business

### Notifications and the day of care

WebPT advertises text, email and phone reminders. Its scheduler links intake and insurance-verification work with the chart and supports visibility into balances during the check-in workflow. A useful evaluation question is whether a reschedule updates all pending reminders and administrative tasks, rather than merely changing the visible calendar block. [[WE02][WE02]]

### Documentation, billing and rehabilitation support

The suite includes clinical documentation, billing and patient-engagement products. Billing options differ by practice needs; the public material distinguishes Therabill and broader billing solutions. Home-exercise support includes a patient app. Do not assume a home-exercise app is also a complete appointment-management or clinic-discovery application. [[WE01][WE01], [WE07][WE07], [WE08][WE08]]

### Interface design

The scheduler emphasizes color, labels, resource availability and operational information around a visit. Patient intake is clinic-branded and task-specific. This design is suited to a front desk that must resolve paperwork, coverage and payment issues as well as book time. It will naturally expose more operational detail than a small self-pay booking form. [[WE02][WE02], [WE03][WE03]]

### Pricing and implementation

The public pricing structure names Starter, Enhanced and Ultimate, but the inspected page does not publish a reliable universal numeric price. The tier descriptions differ in billing and engagement scope. Request a quote covering the exact documentation, scheduling, intake, billing, claims, engagement, training and migration components needed by the clinic. [[WE06][WE06], [WE07][WE07]]

### How it markets and helps clinics grow

WebPT markets through rehabilitation-specific education, research, webinars, customer stories and demonstrations. Its higher-end engagement offering also promotes clinic growth through campaigns, lead tools, reviews and online scheduling. A clinic buying these tools still needs an acquisition strategy and staff follow-through; the existence of a marketing module does not prove a particular patient-growth result. [[WE01][WE01], [WE06][WE06]]

### Distinctive lesson and demo checks

Study authorization-aware scheduling and the handoff from appointment to documentation to payment. Verify whether online bookings are requests or confirmations, which modules share identities and records, and which patient actions are self-service. For a small non-US self-pay clinic, the relevant lesson may be workflow integrity rather than copying the entire US billing system. [[WE02][WE02], [WE04][WE04], [WE07][WE07], [WE09][WE09]]

## Related reading

Compare [registration and login](../workflows/registration-and-login.md), [recurring scheduling](../workflows/scheduling-and-recurring-plans.md), [rescheduling and cancellations](../workflows/rescheduling-and-cancellations.md), [notifications](../workflows/notifications.md), and [billing and clinical records](../workflows/billing-and-clinical-records.md). For evaluation, use the [demo checklist](../demo-checklist.md).

## Sources

Original source register entries for WebPT. Source labels, URLs, date notes and version qualifications are retained from the report. Product pages establish advertised capabilities; help guides establish documented workflows. No authenticated account or real patient transaction was tested.

<a id="source-we01"></a>
**[WE01][WE01]**  Product, resources and marketing

<a id="source-we02"></a>
**[WE02][WE02]**  Scheduling and authorization tracking

<a id="source-we03"></a>
**[WE03][WE03]**  Digital intake and patient registration

<a id="source-we04"></a>
**[WE04][WE04]**  Current scheduling guidance and request queue

<a id="source-we05"></a>
**[WE05][WE05]**  Online appointment requests and approval

<a id="source-we06"></a>
**[WE06][WE06]**  Pricing tiers and included product categories

<a id="source-we07"></a>
**[WE07][WE07]**  Billing software and clearinghouse options

<a id="source-we08"></a>
**[WE08][WE08]**  Browser access and home-exercise patient app

<a id="source-we09"></a>
**[WE09][WE09]**  Product login launchers

<a id="source-we10"></a>
**[WE10][WE10]**  Patient-relationship-management staff login

<a id="source-we11"></a>
**[WE11][WE11]**  Practice-management product catalogue

[WE01]: https://www.webpt.com/
[WE02]: https://www.webpt.com/products/scheduling
[WE03]: https://www.webpt.com/products/digital-patient-intake
[WE04]: https://www.webpt.com/blog/how-to-manage-your-therapy-clinics-schedule
[WE05]: https://www.webpt.com/blog/switch-to-online-scheduling
[WE06]: https://www.webpt.com/pricing
[WE07]: https://www.webpt.com/products/billing-software
[WE08]: https://www.webpt.com/outpatient-home-health
[WE09]: https://www.webpt.com/login
[WE10]: https://prm.webpt.com/
[WE11]: https://www.webpt.com/management
