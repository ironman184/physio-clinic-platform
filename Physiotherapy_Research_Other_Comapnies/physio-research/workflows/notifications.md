# Notifications

[Research index](../INDEX.md) | [Common patterns](../common-patterns.md)

> Cross-company synthesis of the existing research. Research snapshot: 25 September 2026. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Read messages as part of an event workflow

Booking, moving, cancelling, arriving, missing a visit and leaving an unpaid balance are different events. A successfully sent message is not proof that the appointment or invoice changed correctly. See [common pattern 6](../common-patterns.md#6-communication-is-an-event-workflow).

| Platform / detailed section | Documented communication | Operational limit or check |
| --- | --- | --- |
| [Cliniko](../companies/cliniko.md#notifications) | Email/SMS confirmations and reminders can include form/cancellation links; staff rescheduling can trigger updates. | The documented waitlist is staff-managed, not proof of automated gap-filling offers. ([CL09](../companies/cliniko.md#source-cl09), [CL11](../companies/cliniko.md#source-cl11), [CL13](../companies/cliniko.md#source-cl13)) |
| [Jane](../companies/jane.md#reminders-waitlists-and-communication) | Waitlist notification tools can match openings and temporarily hold offers; secure portal messaging has a clinician-started flow. | Automatic waitlist notification access is limited to Thrive and eligible legacy plans; region/channel scope matters. ([JA04](../companies/jane.md#source-ja04), [JA10](../companies/jane.md#source-ja10), [JA11](../companies/jane.md#source-ja11)) |
| [Nookal](../companies/nookal.md#confirmation-and-reminder-system) | Confirmation campaigns can be scoped by service/class, location and practitioner, with forms and separate clinic/practitioner notifications. | Consent, SMS credits and overlapping campaigns can affect delivery or duplication. ([NO04](../companies/nookal.md#source-no04), [NO12](../companies/nookal.md#source-no12)) |
| [Zanda](../companies/zanda.md#notification-behaviour) | Email/SMS reminders, reply keywords and configurable portal-event notifications. | An SMS cancellation does not automatically delete the invoice; overlapping rules can duplicate messages. ([ZA08](../companies/zanda.md#source-za08), [ZA09](../companies/zanda.md#source-za09), [ZA10](../companies/zanda.md#source-za10)) |
| [TM3](../companies/tm3.md#communication-and-filling-openings) | Scheduled email/SMS, confirmations, waitlist acceptance windows and payment-request follow-ups. | A branded SMS sender is not necessarily reply-capable; older message charges are not a current quote. ([TM07](../companies/tm3.md#source-tm07), [TM08](../companies/tm3.md#source-tm08)) |
| [WebPT](../companies/webpt.md#notifications-and-the-day-of-care) | Text, email and phone reminders are advertised alongside intake/coverage/check-in work. | Verify whether a move updates pending reminders and tasks; the report proposes this check rather than proving it. ([WE02](../companies/webpt.md#source-we02)) |
| [Prompt](../companies/prompt.md#notifications-and-schedule-recovery) | Email/text reminders; Plus adds waitlist, lead and underbooked-patient follow-up tools. | Underbooking is fewer planned future visits, not a no-show. Confirm module inclusion and delivery/opt-out handling. ([PR03](../companies/prompt.md#source-pr03), [PR07](../companies/prompt.md#source-pr07)) |
| [Raintree](../companies/raintree.md#recovering-an-empty-slot) | Connect supports two-way messages, reminders, campaigns and waitlist text/email invitations. | Some gap-filling offers are first-come-first-served, not exclusive holds; coordinate Connect and Touchpoints. ([RA03](../companies/raintree.md#source-ra03), [RA04](../companies/raintree.md#source-ra04), [RA06](../companies/raintree.md#source-ra06)) |
| [Halaxy](../companies/halaxy.md#notifications) | Email/SMS reminders, confirmations and reply handling; settings have patient/practitioner/location/group overrides. | Message length affects paid SMS units; waitlist messaging is not automatically an offer engine. ([HA13](../companies/halaxy.md#source-ha13), [HA14](../companies/halaxy.md#source-ha14)) |
| [splose](../companies/splose.md#notifications-and-financial-follow-up) | Service-specific appointment templates; invoice reminders are separately configured. | Accounting software can duplicate invoice reminders. Consent, timezone, contact details and SMS credits affect delivery. ([SP10](../companies/splose.md#source-sp10), [SP11](../companies/splose.md#source-sp11)) |

## Waitlists are not one feature

A stored preference list, an automatically matched opening, an exclusive temporary hold and a first-come-first-served invitation have different behaviour. The company sections above identify which pattern was actually documented; do not turn a waitlist checkbox into a claim of automated gap filling.

## Validation route

Use [demo tests 6 and 7](../demo-checklist.md#a-demo-that-reveals-the-real-system): two acceptances for one opening, expired offers, missing consent, invalid numbers, failed delivery and duplicated events. Check that a change replaces outdated reminders. Delivery logs, retry safety and duplicate prevention are evaluation requirements here, not verified capabilities of every vendor.
