# Physiotherapy research index

Research snapshot: **25 September 2026**. This is the existing report reorganized into focused Markdown files, not a fresh verification of vendor claims or prices. It covers a curated shortlist of ten platforms, not a verified global market-share ranking.

## How to use this reference

Start with the task table below. Read one relevant workflow file, then follow its links into only the company sections needed. Company files retain the full original profiles and source registers; workflow files are shorter cross-company guides. Do not load every file by default.

Treat competitor research, analysis and product recommendations as reference, **not approved requirements**. Keep actual product decisions in your project's own requirements. Preserve region, plan, version, date and unresolved-question qualifications. A marketing claim, an older help guide and a future roadmap item are not interchangeable.

## Choose the next file

| Task | Read first |
| --- | --- |
| Understand the ten companies and main differences | [overview.md](overview.md) |
| Learn shared patterns and the proposed build order | [common-patterns.md](common-patterns.md) |
| Design patient/staff registration, identity, login or family access | [registration-and-login.md](workflows/registration-and-login.md) |
| Model working hours, recurring visits, conflicts or treatment plans | [scheduling-and-recurring-plans.md](workflows/scheduling-and-recurring-plans.md) |
| Change one visit, enforce a cutoff or handle cancellation | [rescheduling-and-cancellations.md](workflows/rescheduling-and-cancellations.md) |
| Design reminders, event messages or waitlist offers | [notifications.md](workflows/notifications.md) |
| Model notes, invoices, payments, refunds or package credits | [billing-and-clinical-records.md](workflows/billing-and-clinical-records.md) |
| Study pricing, positioning, acquisition, migration or business models | [business-and-marketing.md](business-and-marketing.md) |
| Evaluate a product or turn unknowns into test cases | [demo-checklist.md](demo-checklist.md) |

## Full company profiles

[Cliniko](companies/cliniko.md) | [Jane](companies/jane.md) | [Nookal](companies/nookal.md) | [Zanda](companies/zanda.md) | [TM3](companies/tm3.md) | [WebPT](companies/webpt.md) | [Prompt](companies/prompt.md) | [Raintree](companies/raintree.md) | [Halaxy](companies/halaxy.md) | [splose](companies/splose.md)

Each profile includes patient/staff access, scheduling, changes, notifications, clinical/financial operations, interface design, pricing, marketing, distinctive lessons, demo checks and its original source register. Headings provide links to individual topics.

## Evidence and source handling

All **138 original source codes, URLs and register descriptions** are retained in the relevant company files. A source-code link in an overview or workflow opens that company's source-register entry; the entry links to the original vendor page. Each company file also keeps direct source links beside its detailed claims.

The original study relied on public official pages, guides and training material. No authenticated account or real patient transaction was tested. An unresolved detail is not evidence that a feature is absent. Re-check time-sensitive facts before a purchase or an implementation that depends on present vendor behaviour.

## Repository setup

Copy the `docs/physio-research/` folder into the repository. Merge the package's root `AGENTS.md` guidance into an existing `AGENTS.md`; do not overwrite unrelated project instructions. The previous single-file Markdown remains the unchanged archive outside this package.
