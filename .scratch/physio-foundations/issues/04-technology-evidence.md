# Compare technology choices against clinic invariants

Parent: ../map.md
Type: research
Label: wayfinder:research
Status: resolved
Assignee: Codex
Blocked by: none

## Question

What are the defensible client, backend, persistence, and testability options for this product? Verify primary documentation for Flutter alternatives, Flutter structure, transactional booking, and operations. Explain trade-offs without selecting a stack before launch scope and team constraints are known.

## Answer

2026-09-26: Primary documentation supports credible Flutter, Expo and browser delivery options, as well as transactional booking designs on Firestore or PostgreSQL. A relational design deserves first investigation for interval reservations, related records and entitlement reporting; that is an engineering recommendation, not an approved choice or benchmark. Module/transaction design addresses the observed defects regardless of client framework.

Assets: [Technology options](../../../docs/discovery/2026-09-26/technology-options.md), [candidate domain and architecture](../../../docs/discovery/2026-09-26/proposed-domain-and-architecture.md). Country/contractual requirements, hosting plans, runtime compatibility, cost, performance and owner skill fit remain unresolved; research did not deploy a candidate.
