# Establish what the existing system actually does

Parent: ../map.md
Type: research
Label: wayfinder:research
Status: resolved
Assignee: Codex with standards_audit and spec_audit
Blocked by: none

## Question

What does the present application implement, where does it violate its documented intent or safety/correctness invariants, what remains useful, and what verification is possible locally?

## Comments

2026-09-26: Parallel independent Standards and Spec audits at snapshot `affb1b73b6d4cf1e4ad5143ad65f4827272b6579`. Whole-codebase scope requested for confirmation; no arbitrary diff baseline invented.

## Answer

2026-09-26: The current source has concrete authorization, state, retry and partial-commit defects. It also contains a substantial but pending scheduling draft; faithfully copying that draft would reproduce some defects. Independent reports preserve Standards and Spec as separate axes. Eight original-code behavioural probes and one import-order probe ran with an explicitly limited in-memory adapter; a full build, Flutter tests, real Firebase integration and production deployment were not verified.

Assets: [Standards and code audit](../../../docs/discovery/2026-09-26/standards-and-code-audit.md), [Spec and product audit](../../../docs/discovery/2026-09-26/spec-and-product-audit.md), [reproduction](../../../docs/discovery/2026-09-26/evidence/scheduling-reproduction.cjs).

Research is resolved for this source snapshot. Live-deployment status and the repair/rebuild decision remain separate open questions.
