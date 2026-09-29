# Scheduling and recurring plans

[Research index](../INDEX.md) | [Common patterns](../common-patterns.md)

> Cross-company synthesis of the existing research. Research snapshot: 25 September 2026. This package reorganizes the existing report; vendor facts and prices have not been re-verified.


## Three things to keep separate

The original synthesis distinguishes working availability, actual booked visits, and the larger treatment plan or entitlement. A free calendar gap is not by itself proof that the right treatment can be booked. See [availability rules](../common-patterns.md#2-availability-is-a-set-of-rules-not-empty-calendar-space) and [series exceptions](../common-patterns.md#3-a-treatment-series-needs-individual-exceptions).

| Platform / detailed section | Scheduling model | Important boundary |
| --- | --- | --- |
| [Cliniko](../companies/cliniko.md#scheduling-and-recurring-treatment) | Staff-defined repeating appointments with interval and count; separate group-capacity controls and a staff-managed waitlist. | Individual visits, group capacity and a waitlist are different objects. ([CL08](../companies/cliniko.md#source-cl08), [CL13](../companies/cliniko.md#source-cl13), [CL16](../companies/cliniko.md#source-cl16)) |
| [Jane](../companies/jane.md#recurring-appointments-and-the-staff-calendar) | Repeated appointments preview working shifts, conflicts and unavailable dates before saving. | Study the conflict preview, rather than creating a series blindly. ([JA08](../companies/jane.md#source-ja08), [JA09](../companies/jane.md#source-ja09)) |
| [Nookal](../companies/nookal.md#recurring-schedules-and-changes) | Case/service appointments; staff schedules include recurring hours, breaks and leave. Recurring dates are checked before saving. | An empty slot alone does not identify the correct case or service. ([NO08](../companies/nookal.md#source-no08), [NO10](../companies/nookal.md#source-no10), [NO11](../companies/nookal.md#source-no11)) |
| [Zanda](../companies/zanda.md#recurring-appointments) | Edits can target one occurrence, that point forward, or the full recurring set. | Rebuilding future visits is constrained by invoices/paid visits. ([ZA06](../companies/zanda.md#source-za06)) |
| [TM3](../companies/tm3.md#linked-appointments-and-recurring-availability) | Recurring practitioner/location/room availability; companion and additional-service booking can link visits. | Linked visits and Book Next are not proof of unrestricted recurring-series functionality. ([TM03](../companies/tm3.md#source-tm03), [TM11](../companies/tm3.md#source-tm11), [TM12](../companies/tm3.md#source-tm12)) |
| [WebPT](../companies/webpt.md#scheduling-rules) | Provider, patient, room, equipment and location scheduling with authorization visits/units and expiry. | The report does not establish every recurring-series edit scope; demonstrate the full plan. ([WE02](../companies/webpt.md#source-we02), [WE04](../companies/webpt.md#source-we04)) |
| [Prompt](../companies/prompt.md#repeat-treatment-and-the-staff-workflow) | Plans of care and multiple visits; Version 10 promotes bulk recurring creation/changes with conflict checks. | Release material is not proof of enabled functionality in every offered account. ([PR03](../companies/prompt.md#source-pr03), [PR09](../companies/prompt.md#source-pr09)) |
| [Raintree](../companies/raintree.md#appointments-and-recurring-treatment) | The 2023 training describes daily/weekly/monthly block booking with case, provider, location and restrictions. | That establishes a documented model, not the layout or complete behaviour of the 2026 interface. ([RA05](../companies/raintree.md#source-ra05), [RA08](../companies/raintree.md#source-ra08)) |
| [Halaxy](../companies/halaxy.md#scheduling-and-repeat-sessions) | Fixed intervals or dynamic gaps; repeats use selected weekdays and an end date/count; appointments connect to service fees/resources. | A separate express/on-demand queue is not the same as fixed recurring treatment. ([HA04](../companies/halaxy.md#source-ha04), [HA09](../companies/halaxy.md#source-ha09), [HA11](../companies/halaxy.md#source-ha11), [HA17](../companies/halaxy.md#source-ha17)) |
| [splose](../companies/splose.md#scheduling-and-recurring-work) | Recurring appointments and repeated/one-off availability; another-location booking can block availability. | An appointment and a support activity are different; support activity does not send a patient appointment notification. ([SP04](../companies/splose.md#source-sp04), [SP06](../companies/splose.md#source-sp06), [SP07](../companies/splose.md#source-sp07)) |

## Related decisions

For changing a single occurrence, read [rescheduling and cancellations](rescheduling-and-cancellations.md). For whether a future visit reserves or consumes a session, read [billing and clinical records](billing-and-clinical-records.md). Do not infer one rule from the other.

## Validation route

Use [demo tests 2, 3 and 5](../demo-checklist.md#a-demo-that-reveals-the-real-system): eight one-hour weekly visits, a holiday, therapist leave, a cross-location conflict, a single-visit move and a package/authorization limit. These are proposed tests, not claims that each product passes them.
