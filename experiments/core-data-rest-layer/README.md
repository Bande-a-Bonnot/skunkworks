# Core Data REST Layer

> Experiment: use Core Data as an object graph / query / change-tracking layer on top of a Web REST API, rather than as a local-first SQLite/CloudKit persistence stack.

## Status

`custom-store spike`

## Why

Core Data is often treated as "the local database thing" or "an ORM for SQLite", but its more interesting identity is an object graph management framework: identity, relationships, faults, validation, change tracking, fetch requests, merge policies, undo, and contexts.

This experiment asks: what happens if the persistent backing is not local SQLite or CloudKit, but a REST API? The meaningful target is a custom persistent store / incremental store, not a conventional REST-to-local-cache sync layer.

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
- `Sources/CoreDataRESTLayer/` — REST models/client, API/model version mapping, programmatic Core Data model, projection sync, and `RESTIncrementalStore`.
- `Sources/CoreDataRESTLayerTestServer/` — embedded deterministic HTTP server for tests.
- `Tests/CoreDataRESTLayerTests/` — acceptance tests for sync/edit/push/conflict flows.
- `todos/` — local task breakdown.

## Quick Start

```bash
cd experiments/core-data-rest-layer
swift test
```

The test harness starts an embedded REST server on `127.0.0.1:0`. The current meaningful tests use `RESTIncrementalStore` so Core Data fetches, relationship faults, and `context.save()` hit REST endpoints directly. Earlier projection-sync tests still exist but are not the target architecture.

## Notes / Findings

- Core Data's precise phrase is "object graph and persistence framework". This experiment should lean on the object graph part and interrogate the persistence part.
- Avoid building a full generic REST ORM. Keep the first API tiny and concrete.
- Treat REST as remote truth with its own semantics, not as a lossy SQL endpoint.
- Prefer an embedded local server over static fixtures so tests exercise real HTTP semantics.
- Important correction: a materialized Core Data projection is the wrong target for this experiment. It is ordinary sync/cache architecture, not Core Data over REST.
- `NSIncrementalStore` is the relevant path: `NSFetchRequest` can call `GET /projects`; relationship faulting can call `GET /projects/{id}/tasks`; `context.save()` can call `PATCH /tasks/{id}`.
- Relationship faulting can walk cursor, offset, or numbered-page REST endpoints, but it currently does so eagerly and synchronously.
- Save conflicts can mark the dirty object and throw `RESTIncrementalStoreError.conflict(remote:)`.
- Non-conflict HTTP failures from fetch/fault/save paths throw `RESTIncrementalStoreError.httpStatus`, which also bridges to a stable `NSError` domain/code/userInfo.
- Core Data's store API is synchronous, so REST calls inside an incremental store are blocking unless wrapped by a higher-level execution policy; use private-queue contexts for app-facing operations.
- Pagination style is part of the remote contract and leaks into sync/completeness semantics; it should not be hidden as a transparent relationship fault.
- Keep API version, local Core Data model version, and per-resource optimistic concurrency version separate.

## Next Ideas

- [x] Decide first spike approach: embedded REST server plus Core Data materialized projection.
- [x] Create minimal Swift package/app harness.
- [x] Model project/task resources.
- [x] Implement embedded local REST server.
- [x] Simulate stale writes/conflicts.
- [x] Later: simulate latency and pagination.
- [ ] Write down which Core Data features remain pleasant over REST in more detail.

## Cleanup / Graduation

Graduate if this yields a reusable pattern for app architecture. Archive if the custom-store route is mostly pain but capture the findings in `docs/solutions/`.
