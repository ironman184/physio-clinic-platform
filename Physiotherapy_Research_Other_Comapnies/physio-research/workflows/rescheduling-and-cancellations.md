# Rescheduling and cancellations

[Research index](../INDEX.md) | [Common patterns](../common-patterns.md)

> Cross-company synthesis of the existing research. Research snapshot: 25 September 2026. This package reorganizes the existing report; vendor facts and prices have not been re-verified.

## Patient access and change rules

| **Platform** | **Patient front door** | **Change behaviour and qualification** |
| --- | --- | --- |
| [Cliniko](../companies/cliniko.md) | Booking without a patient account. | Patient cancellation is configurable; direct patient rescheduling is not supported in the current guide. Paid-online rules differ. [[CL03](../companies/cliniko.md#source-cl03), [CL09](../companies/cliniko.md#source-cl09), [CL10](../companies/cliniko.md#source-cl10)] |
| [Jane](../companies/jane.md) | Clinic portal; linked native app in Canada/US. | Patient cancel/reschedule subject to clinic settings and cutoff; app and clinic identities are distinct. [[JA04](../companies/jane.md#source-ja04), [JA05](../companies/jane.md#source-ja05), [JA06](../companies/jane.md#source-ja06)] |
| [Nookal](../companies/nookal.md) | Details or Online Booking Code; optional authenticated portal. | Cancellation is documented. Exact patient self-rescheduling conditions need a demo. Portal is tier-dependent. [[NO04](../companies/nookal.md#source-no04), [NO06](../companies/nookal.md#source-no06), [NO03](../companies/nookal.md#source-no03)] |
| [Zanda](../companies/zanda.md) | Email/password portal plus verification. | Self-move changes date/time, not practitioner/service/location. Paid cancellation is not an automatic refund. [[ZA03](../companies/zanda.md#source-za03), [ZA05](../companies/zanda.md#source-za05), [ZA07](../companies/zanda.md#source-za07)] |
| [TM3](../companies/tm3.md) | Connect; current guides include a magic-link screen. | Older portal cancellation is documented; current change, refund and series rules need version-specific confirmation. [[TM04](../companies/tm3.md#source-tm04), [TM13](../companies/tm3.md#source-tm13)] |
| [WebPT](../companies/webpt.md) | Digital intake and product-specific patient surfaces. | Online scheduling guidance includes staff-approved requests. Exact patient change rules need confirmation. [[WE03](../companies/webpt.md#source-we03), [WE04](../companies/webpt.md#source-we04), [WE08](../companies/webpt.md#source-we08)] |
| [Prompt](../companies/prompt.md) | Task links; patient entry screen sends a confirmation code. | Official pages conflict on patient self-rescheduling. Resolve before purchase. [[PR06](../companies/prompt.md#source-pr06), [PR02](../companies/prompt.md#source-pr02), [PR03](../companies/prompt.md#source-pr03)] |
| [Raintree](../companies/raintree.md) | Patient portal, digital intake and check-in. | Booking is advertised; exact self-change, notice and financial rules require a demonstration. [[RA02](../companies/raintree.md#source-ra02), [RA03](../companies/raintree.md#source-ra03)] |
| [Halaxy](../companies/halaxy.md) | Directory, portal and secure appointment-summary links. | Self-change is configurable; cancellation status affects billing/refund behaviour. A reschedule creates a replacement visit. [[HA03](../companies/halaxy.md#source-ha03), [HA10](../companies/halaxy.md#source-ha10)] |
| [splose](../companies/splose.md) | Branded booking pages and appointment-message links. | Self-move keeps provider/service/location; changed price can block it. No automatic refund on paid self-cancel. [[SP04](../companies/splose.md#source-sp04), [SP05](../companies/splose.md#source-sp05)] |

**Do not merge these capabilities.** Booking without an account, a full patient portal, a native mobile app, a directory listing and a request awaiting approval solve different problems. Likewise, cancelling a visit, refunding money and returning a package credit are different operations. The profiles show where those distinctions matter.

## Series edits and money need separate checks

| Example | Detail hidden by a simple feature checkbox |
| --- | --- |
| [Zanda](../companies/zanda.md#patient-self-rescheduling) | Move date/time while keeping practitioner, service and location. Series edits have explicit scopes. Portal cancellation is not an automatic refund; SMS cancellation has its own invoice caveat. ([ZA05](../companies/zanda.md#source-za05), [ZA06](../companies/zanda.md#source-za06), [ZA07](../companies/zanda.md#source-za07), [ZA09](../companies/zanda.md#source-za09)) |
| [Halaxy](../companies/halaxy.md#patient-changes-and-financial-side-effects) | Rescheduling creates a new visit and cancels the original. The configured cancellation status can change invoice and refund handling. ([HA10](../companies/halaxy.md#source-ha10)) |
| [splose](../companies/splose.md#patient-rescheduling) | Self-move keeps provider/service/location and can be blocked by a changed price. Paid self-cancellation does not automatically refund. ([SP05](../companies/splose.md#source-sp05)) |
| [Cliniko](../companies/cliniko.md#rescheduling-and-cancellation) | Direct patient rescheduling is not supported in the cited guide. Staff moves and configurable patient cancellation are different routes; fully prepaid and deposit bookings differ. ([CL09](../companies/cliniko.md#source-cl09), [CL10](../companies/cliniko.md#source-cl10)) |
| [Prompt](../companies/prompt.md#important-contradiction-patient-rescheduling) | Official pages conflict on patient self-rescheduling. Keep the answer unresolved until the product/version/module is demonstrated. ([PR02](../companies/prompt.md#source-pr02), [PR03](../companies/prompt.md#source-pr03)) |

## Product-design implications, not approved requirements

The original recommendation starts with [controlled admin-led changes](../common-patterns.md#keep-the-first-change-workflow-controlled), then adds [bounded patient self-service](../common-patterns.md#then-add-carefully-bounded-patient-self-service). A proposed replacement is not a confirmed booking, and changing one visit must not silently change the remaining series.

For payment, refund and package balance consequences, use [billing and clinical records](billing-and-clinical-records.md). For invalidating/replacing reminders, use [notifications](notifications.md).

## Validation route

Use [demo tests 3 and 4](../demo-checklist.md#a-demo-that-reveals-the-real-system). Observe appointment status, the original/replacement visit, the invoice, refund, package credit, audit trail and message separately. Unresolved behaviour stays unresolved.
