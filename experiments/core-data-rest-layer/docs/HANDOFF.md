# Core Data REST Layer Handoff

**URN:** `skunkworks::local::experiment::core-data-rest-layer::handoff::019e4c87-dd7e-708c-be24-fda71b3451b3`  
**Last updated:** 2026-05-21  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on `experiments/core-data-rest-layer/`.

---

## Purpose

Explore whether Core Data is useful as an object graph, identity map, validation, and change-tracking layer over REST-backed remote resources — not merely as a local SQLite/CloudKit persistence framework.

## Current State

Documentation-only seed exists:

- `README.md` describes the experiment, hypotheses, candidate approaches, and first spike.
- `docs/initial-questions.md` captures conceptual/API/Core Data questions.
- Local agent/process scaffold now exists:
  - `AGENTS.md`
  - `docs/HANDOFF.md`
  - `docs/README.md`
  - `docs/{brainstorms,plans,solutions,runbooks}/`
  - `todos/README.md`

No runnable Swift harness exists yet.

## Working Direction

Do not start with a generic REST ORM. The likely first spike is a tiny fixture-backed materialized remote view:

```text
REST-like fixtures -> Core Data projection -> fetch/edit/change tracking -> documented findings
```

A custom persistent store may be explored later after the basic semantics are clearer.

## Local Todos

- `001` — `todos/001-ready-p1-write-first-spike-plan.md`
- `002` — `todos/002-pending-p2-build-fixture-backed-projection.md`
- `003` — `todos/003-pending-p3-evaluate-custom-persistent-store.md`

## Open Questions

- Is Core Data useful primarily as an identity/change-tracking layer here?
- How much REST behavior should be visible to app code?
- Can Core Data fetch/predicate ergonomics coexist with server-side pagination/filtering limits?
- Where should conflict state live?

## Verification

Current verification is file/catalog consistency only. Once code exists, add the smallest useful command here and in `README.md`.

## Next Action

Write `docs/plans/2026-05-21-core-data-rest-layer-first-spike-plan.md`, then implement the smallest fixture-backed projection spike.
