# Demo checklist

[Research index](INDEX.md)

> Proposed evaluation tests, not vendor capabilities. Research snapshot: 25 September 2026. Original report pages: 25. This package reorganizes the existing report; vendor facts and prices have not been re-verified.

## A demo that reveals the real system

Use the same fictional clinic and patient in every demo. The following are proposed tests, not claims that all ten vendors pass them. Ask the demonstrator to show both the patient screen and the staff record after each action.

| **Test** | **What a convincing demonstration must show** |
| --- | --- |
| 1. Register without duplication | Create a patient at reception, then book online with the same details. Show matching, a changed phone number, a parent booking for a child and access to the correct record. |
| 2. Build a treatment series | Book eight one-hour weekly sessions. Put a holiday, another-location booking and a therapist absence in the middle. Show conflict preview before saving. |
| 3. Change one visit only | Move visit four to another time or therapist. Show patient approval if required, unchanged future visits, the audit trail and replacement reminders. |
| 4. Cancel a paid visit | Compare before-cutoff, late cancellation and no-show. Show the appointment state, invoice, refund, package credit and patient message separately. |
| 5. Exhaust a package or authorization | Use the final session, then attempt another booking. Show whether future bookings reserve units and what happens when a cancellation releases one. |
| 6. Recover an opening safely | Have two patients accept one offered slot. Show how overbooking is prevented, how the losing patient is informed and when the offer expires. |
| 7. Break communication | Use missing consent, an invalid phone, a failed SMS and a duplicated event. Show delivery status, staff follow-up and prevention of duplicate messages. |
| 8. Export and leave | Export a sample including patients, notes, attachments, appointments and financial history. Check readability and access during the final migration period. |

### Security and integration questions

Request a permission matrix for admin, therapist and patient; MFA and recovery rules; access logs; hosting and backup details; incident procedures; data ownership and retention terms; and documented integration/export capabilities. Do not treat a vendor's general compliance statement as proof that the clinic's configuration is appropriate.

### What to record

For each test, capture available / configuration needed / paid add-on / manual workaround / not supported / unresolved. Record the version, region and plan. A manual workflow can be acceptable; an undisclosed manual workflow is the larger risk.

## Vendor-specific questions

[Cliniko](companies/cliniko.md#distinctive-lesson-and-demo-checks), [Jane](companies/jane.md#discovery-limitations-and-demo-checks), [Nookal](companies/nookal.md#important-boundaries-and-demo-checks), [Zanda](companies/zanda.md#best-lesson-and-demo-checks), [TM3](companies/tm3.md#switching-risk-and-strongest-lesson), [WebPT](companies/webpt.md#distinctive-lesson-and-demo-checks), [Prompt](companies/prompt.md#strongest-lesson-and-demo-checks), [Raintree](companies/raintree.md#strongest-lesson-and-demo-checks), [Halaxy](companies/halaxy.md#strongest-lesson-and-demo-checks), [splose](companies/splose.md#roadmap-boundary-and-demo-checks).

Record unresolved answers rather than converting them into a feature claim. The original report did not run these tests against authenticated vendor accounts.
