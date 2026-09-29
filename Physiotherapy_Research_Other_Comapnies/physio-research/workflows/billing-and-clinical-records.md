# Billing and clinical records

[Research index](../INDEX.md) | [Common patterns](../common-patterns.md)

> Cross-company synthesis of the existing research. Research snapshot: 25 September 2026. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Keep the records distinct

The original synthesis separates appointment status, invoice, payment/refund and session entitlement. A cancellation can affect some of these without automatically affecting the others. This is a design interpretation of the examples, not a verified shared database design. See [common pattern 4](../common-patterns.md#4-cancellation-is-not-one-database-update).

| Platform / detailed section | Clinical and financial connection | Rule that needs attention |
| --- | --- | --- |
| [Cliniko](../companies/cliniko.md#clinical-work-and-money) | Records, notes, invoices, payments, reporting and telehealth; online booking can take Stripe payments. | Fully prepaid versus deposit bookings have different patient cancellation rules. ([CL03](../companies/cliniko.md#source-cl03), [CL10](../companies/cliniko.md#source-cl10), [CL14](../companies/cliniko.md#source-cl14)) |
| [Jane](../companies/jane.md#clinical-and-commercial-workflow) | Intake, charting, invoices, payments, telehealth and optional insurance; Physitrack exercise integration. | Region, plan and add-ons define the actual bundle; do not assume all insurance or AI/website tools are included. ([JA01](../companies/jane.md#source-ja01), [JA02](../companies/jane.md#source-ja02), [JA03](../companies/jane.md#source-ja03)) |
| [Nookal](../companies/nookal.md#clinical-financial-and-operational-work) | Patient records, notes, intake, invoicing, payments and reporting with case-linked appointments. | The same patient can have multiple cases; regional claims and additional AI/voice costs need checking. ([NO01](../companies/nookal.md#source-no01), [NO03](../companies/nookal.md#source-no03), [NO08](../companies/nookal.md#source-no08)) |
| [Zanda](../companies/zanda.md#packages-the-most-important-accounting-detail) | Session packs can track sessions, time or money, with expiry/referral-related limits. | A unit is consumed on invoice allocation, not simply on attendance; cancellation/refund and allocation reversal are separate checks. ([ZA07](../companies/zanda.md#source-za07), [ZA11](../companies/zanda.md#source-za11), [ZA12](../companies/zanda.md#source-za12)) |
| [TM3](../companies/tm3.md#insurance-registration) | Cases, forms, documents, authorizations, insurer billing and referral-connected work; package credits and subscriptions in Connect guidance. | A submitted insurer pre-authorization code can be an appointment note rather than a formal authorization record. ([TM05](../companies/tm3.md#source-tm05), [TM08](../companies/tm3.md#source-tm08), [TM09](../companies/tm3.md#source-tm09), [TM10](../companies/tm3.md#source-tm10)) |
| [WebPT](../companies/webpt.md#documentation-billing-and-rehabilitation-support) | Rehab documentation, authorization-aware scheduling, billing and home-exercise patient support. | Billing options/modules differ. An authorization limit is not interchangeable with a self-pay package balance. ([WE02](../companies/webpt.md#source-we02), [WE07](../companies/webpt.md#source-we07), [WE08](../companies/webpt.md#source-we08)) |
| [Prompt](../companies/prompt.md#clinical-work-and-billing) | Core EMR connects documentation, billing, clearinghouse workflows and analytics; work queues highlight unfinished tasks. | Kiosk can collect forms, insurance details and balances, but it is a named product whose inclusion must be checked. ([PR02](../companies/prompt.md#source-pr02), [PR08](../companies/prompt.md#source-pr08)) |
| [Raintree](../companies/raintree.md#care-billing-and-operational-work) | Portal care information, outcomes and payments; Connect includes payment plans, stored methods, eFax and telehealth capabilities. | Bundle, interfaces and deployment matter; future authorization/claims agents are not delivered September 2026 functionality. ([RA02](../companies/raintree.md#source-ra02), [RA04](../companies/raintree.md#source-ra04), [RA08](../companies/raintree.md#source-ra08)) |
| [Halaxy](../companies/halaxy.md#forms-clinical-work-and-billing) | Fee-linked appointments connect invoicing and clinical work; forms update linked fields and only selected records are shared. | Cancellation status can change money handling. Package eligibility uses service/practitioner/location; a mismatch can create another unpaid booking. ([HA06](../companies/halaxy.md#source-ha06), [HA10](../companies/halaxy.md#source-ha10), [HA11](../companies/halaxy.md#source-ha11), [HA15](../companies/halaxy.md#source-ha15), [HA16](../companies/halaxy.md#source-ha16)) |
| [splose](../companies/splose.md#prepayment-detail-worth-testing) | Notes, forms, cases, reporting, exercise integration and support-activity billing. | Prepayment is linked to draft-invoice credit; arrival helps finalize/apply it. Paid self-cancellation does not automatically refund. ([SP01](../companies/splose.md#source-sp01), [SP05](../companies/splose.md#source-sp05), [SP06](../companies/splose.md#source-sp06), [SP09](../companies/splose.md#source-sp09)) |

## Session-ledger decisions, not competitor facts

The original [session-ledger recommendation](../common-patterns.md#decide-the-session-ledger-before-drawing-the-balance-screen) asks when a unit is available, reserved, completed, credited, charged for cancellation or manually adjusted. Decide whether future bookings reserve units, whether no-shows consume them and whether a refund restores a session. Do not assume all vendors use the same answers.

## Validation route

Use [demo tests 4, 5 and 8](../demo-checklist.md#a-demo-that-reveals-the-real-system): a paid cancellation, exhausted package/authorization and an export containing notes, attachments, appointments and financial history. For commercial inclusion and usage fees, use [business and marketing](../business-and-marketing.md).
