# Decide the foundations of the physiotherapy platform

Label: wayfinder:map
Status: charted — initial research complete; product decisions await the user
Created: 2026-09-26

## Destination

Establish a product scope, explicit scheduling and change policies, a domain model, and a justified architecture/technology choice that the owner can understand and contribute to. Decide whether to rebuild or repair, with evidence and a reviewable route into implementation.

This destination is inferred from the owner's request; launch scope and success criteria remain open in [Choose the first users and launch scope](issues/01-launch-scope.md).

## Notes

- This effort plans and investigates; it does not implement a replacement or delete the existing application.
- The owner prefers considering a fresh build, but has not selected the new scope or stack.
- Use code-review, codebase-design, wayfinder, research, and domain-modeling. The separate `grilling` dependency referenced by wayfinder/grill-with-docs was not found in the available local skill locations; conduct the interview directly and never supply the human's answers.
- No `docs/agents/issue-tracker.md` exists. Use the local tracker convention in `.agents/skills/setup-matt-pocock-skills/issue-tracker-local.md`; `/setup-matt-pocock-skills` is available if tracker integration is wanted later.
- Review scope is provisionally the entire current working tree at `affb1b73b6d4cf1e4ad5143ad65f4827272b6579`; a comparison-point question is pending. This is not a claim to have run a three-dot diff review.
- Existing specs are evidence of prior intent, including a scheduling draft explicitly pending review. Competitor notes are references, not approved requirements.
- Research outputs live in `docs/discovery/2026-09-26/`. Shared-checkout agents own separate files; no branch switching, external issues, deployment, or production data access is needed for this investigation.
- Ticket names are the human-facing references. `Blocked by` numbers are the local tracker's dependency representation. Open/unclaimed tickets use `Status: open`; claim before work and resolve research by recording an answer and its asset link.
- Do not treat a recommendation in a research report as an accepted product or architecture decision. Human decisions remain open until a live exchange resolves them.

## Decisions so far

No product or architecture decisions have been accepted in this effort yet. The completed research establishes the evidence for the next discussion:

- [Establish what the existing system actually does](issues/02-existing-system.md): separate Standards/Spec audits and limited executable probes identify core defects and unvalidated assumptions.
- [Verify competitor workflows that affect our decisions](issues/03-vendor-workflows.md): a current five-vendor subset confirms material restrictions and preserves unresolved claims.
- [Compare technology choices against clinic invariants](issues/04-technology-evidence.md): documented alternatives and conditional trade-offs; no stack selected.

## Not yet specified

- Clinical documentation, exercise programmes, outcomes, referrals, and billing depth depend on the initial users and product promise.
- Integrations and migration detail depend on existing clinic tools, data, contracts, and launch geography.
- Performance and recovery targets depend on clinic size, peak booking activity, operating hours, and acceptable downtime.
- Pricing, support model, expansion to other countries, and insurance workflows depend on whether this is a clinic tool or a commercial platform.
- Concrete learning exercises and implementation slices follow the chosen stack and the owner's existing programming skills.

## Out of scope

- Deleting code, provisioning production systems, migrating real records, deploying a new app, or contacting vendors during this discovery session.
- Copying every competitor feature or assuming all ten vendors have identical workflows.
