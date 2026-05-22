# Core Data REST Layer

> Experiment: use Core Data as an object graph / query / change-tracking layer on top of a Web REST API, rather than as a local-first SQLite/CloudKit persistence stack.

## Status

`runnable spike`

## Why

Core Data is often treated as "the local database thing" or "an ORM for SQLite", but its more interesting identity is an object graph management framework: identity, relationships, faults, validation, change tracking, fetch requests, merge policies, undo, and contexts.

This experiment asks: what happens if the persistent backing is not local SQLite or CloudKit, but a REST API?

## Core Question

Can Core Data provide useful app-side ergonomics over remote resources without pretending the REST API is a local database?

## Hypotheses

- `NSManagedObjectContext` may be valuable as an identity map, unit-of-work, validation boundary, and object graph coordinator even when source-of-truth data is remote.
- A REST-backed Core Data layer could make SwiftUI/app code nicer: fetch predicates, sections, diffing, relationships, temporary IDs, optimistic edits.
- The hard parts will be impedance mismatches: pagination, partial objects, server filtering semantics, conflicts, latency, offline behavior, and relationship faulting.

## Candidate Approaches

### 1. Custom Persistent Store

Implement a custom Core Data persistent store / incremental store that translates fetches and saves to REST calls.

Pros:
- Most literal interpretation of "Core Data on top of REST".
- App code can remain close to normal Core Data usage.

Cons:
- Advanced Core Data surface area.
- REST APIs rarely match Core Data fetch semantics exactly.
- Faulting and relationship loading may become surprising.

### 2. Local Materialized Remote View

Use a normal local Core Data store as a materialized projection of remote API resources, with explicit sync/fetch adapters.

Pros:
- More practical and debuggable.
- Better offline story.
- Easier conflict handling and caching.

Cons:
- Less weird.
- Risks becoming "just another sync layer" instead of testing Core Data as the abstraction.

### 3. Hybrid Spike

Start with the local projection to learn the model, then attempt a minimal custom store for a tiny resource set.

## Minimal Domain

Start with a deliberately small REST-ish model:

- `Project`
  - `id`
  - `name`
  - `updatedAt`
- `Task`
  - `id`
  - `projectId`
  - `title`
  - `status`
  - `updatedAt`

Relationship:

- `Project.tasks`
- `Task.project`

## First Spike

Build a small Swift package or app that can:

1. Start an embedded local REST server bound to `127.0.0.1:0`.
2. Fetch projects/tasks through `URLSession`.
3. Project server resources into a Core Data model for projects/tasks.
4. Expose data through `NSManagedObjectContext` fetches and relationships.
5. Apply local edits and push them back with version/conflict handling.
6. Document where Core Data helps vs where it fights the API boundary.

Plan: `docs/plans/2026-05-22-core-data-rest-layer-first-spike-plan.md`.

## Local Project Files

- `AGENTS.md` — local agent instructions.
- `docs/HANDOFF.md` — current state and exact next action.
- `docs/initial-questions.md` — question bank.
- `Package.swift` — Swift package harness.
- `Sources/CoreDataRESTLayer/` — REST models/client, programmatic Core Data model, projection sync.
- `Sources/CoreDataRESTLayerTestServer/` — embedded deterministic HTTP server for tests.
- `Tests/CoreDataRESTLayerTests/` — acceptance tests for sync/edit/push/conflict flows.
- `todos/` — local task breakdown.

## Quick Start

```bash
cd experiments/core-data-rest-layer
swift test
```

The test harness starts an embedded REST server on `127.0.0.1:0`, fetches through `URLSession`, projects remote resources into an in-memory Core Data store, pushes a dirty local task edit, and verifies stale-write conflict handling.

## Notes / Findings

- Core Data's precise phrase is "object graph and persistence framework". This experiment should lean on the object graph part and interrogate the persistence part.
- Avoid building a full generic REST ORM. Keep the first API tiny and concrete.
- Treat REST as remote truth with its own semantics, not as a lossy SQL endpoint.
- Prefer an embedded local server over static fixtures so tests exercise real HTTP semantics.
- First finding: a materialized Core Data projection makes app-style relationship/fetch access pleasant after explicit sync, but conflict/loading/error state must stay explicit in the model or surrounding sync layer.
- First finding: Core Data dirty tracking is useful as a local unit-of-work marker, but versioned REST conflicts should not be hidden behind `save()` semantics.

## Next Ideas

- [x] Decide first spike approach: embedded REST server plus Core Data materialized projection.
- [x] Create minimal Swift package/app harness.
- [x] Model project/task resources.
- [x] Implement embedded local REST server.
- [x] Simulate stale writes/conflicts.
- [ ] Later: simulate latency and pagination.
- [ ] Write down which Core Data features remain pleasant over REST in more detail.

## Cleanup / Graduation

Graduate if this yields a reusable pattern for app architecture. Archive if the custom-store route is mostly pain but capture the findings in `docs/solutions/`.
