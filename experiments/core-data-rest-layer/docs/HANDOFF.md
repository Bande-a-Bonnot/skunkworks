# Core Data REST Layer Handoff

**URN:** `skunkworks::local::experiment::core-data-rest-layer::handoff::019e4c87-dd7e-708c-be24-fda71b3451b3`  
**Last updated:** 2026-05-22  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on `experiments/core-data-rest-layer/`.

---

## Purpose

Explore whether Core Data is useful as an object graph, identity map, validation, and change-tracking layer over REST-backed remote resources — not merely as a local SQLite/CloudKit persistence framework.

## Current State

Documentation/planning seed exists. No runnable Swift harness exists yet.

Current docs:

- `README.md` describes the experiment, hypotheses, candidate approaches, and first spike.
- `docs/initial-questions.md` captures conceptual/API/Core Data questions.
- `docs/plans/2026-05-22-core-data-rest-layer-first-spike-plan.md` defines the first runnable spike.

Local agent/process scaffold exists:

- `AGENTS.md`
- `docs/HANDOFF.md`
- `docs/README.md`
- `docs/{brainstorms,plans,solutions,runbooks}/`
- `todos/README.md`

## Working Direction

Do not start with a generic REST ORM or custom persistent store.

The first spike should use a real local HTTP boundary:

```text
embedded local REST server -> URLSession client -> Core Data projection -> app-style fetch/edit/sync
```

The embedded server should bind to `127.0.0.1:0` in tests and provide deterministic REST behavior for projects/tasks, including a stale-write conflict path.

## Local Todos

Done:

- `001` — `todos/001-done-p1-write-first-spike-plan.md`

Ready:

- `002` — `todos/002-ready-p1-build-embedded-server-projection.md`

Pending:

- `003` — `todos/003-pending-p3-evaluate-custom-persistent-store.md`
- `004` — `todos/004-pending-p2-add-pagination-and-latency-cases.md`

## Open Questions

- Which tiny server dependency, if any, should be used for the embedded REST server?
- Should first conflict handling use explicit integer `version` fields or HTTP `ETag` / `If-Match`?
- Where should remote loading/error/conflict state live in the Core Data model?
- Should local edits be represented as dirty flags on managed objects, separate pending-change entities, or child-context units of work?
- After the projection spike, does a custom persistent store still seem worth exploring?

## Verification

Current verification is documentation/catalog consistency only.

Expected first implementation command:

```bash
cd experiments/core-data-rest-layer
swift test
```

## Next Action

Implement `todos/002-ready-p1-build-embedded-server-projection.md` following `docs/plans/2026-05-22-core-data-rest-layer-first-spike-plan.md`.
