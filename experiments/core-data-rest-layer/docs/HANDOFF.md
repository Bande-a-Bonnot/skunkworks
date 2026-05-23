# Core Data REST Layer Handoff

**URN:** `skunkworks::local::experiment::core-data-rest-layer::handoff::019e4c87-dd7e-708c-be24-fda71b3451b3`  
**Last updated:** 2026-05-22  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on `experiments/core-data-rest-layer/`.

---

## Purpose

Explore whether Core Data is useful as an object graph, identity map, validation, and change-tracking layer over REST-backed remote resources — not merely as a local SQLite/CloudKit persistence framework.

## Current State

First runnable Swift spike exists and passes tests.

Implemented package:

- `Package.swift`
- `Sources/CoreDataRESTLayer/RemoteModels.swift` — JSON domain models and shared JSON coding.
- `Sources/CoreDataRESTLayer/RESTClient.swift` — `URLSession` client for `GET /projects`, paginated `GET /projects/{projectID}/tasks`, and `PATCH /tasks/{taskID}`.
- `Sources/CoreDataRESTLayer/VersionMapping.swift` — explicit API version / local model version compatibility skeleton.
- `Sources/CoreDataRESTLayer/CoreDataStack.swift` — programmatic Core Data model with `CDProject` / `CDTask`, relationship, version, dirty, and conflict metadata.
- `Sources/CoreDataRESTLayer/ProjectionSync.swift` — pull projection and dirty-task push/conflict recording; task pulls can use cursor, offset, or numbered-page pagination.
- `Sources/CoreDataRESTLayerTestServer/EmbeddedRESTServer.swift` — dependency-free `Network.framework` local HTTP server bound to `127.0.0.1:0`, with pagination and latency hooks.
- `Tests/CoreDataRESTLayerTests/CoreDataRESTLayerTests.swift` — acceptance tests for sync/edit/push, stale-write conflict, pagination, latency, and version headers.

Current docs:

- `README.md` describes the experiment, quick start, and first findings.
- `docs/initial-questions.md` captures conceptual/API/Core Data questions.
- `docs/plans/2026-05-22-core-data-rest-layer-first-spike-plan.md` defines the implemented first spike.
- `docs/solutions/2026-05-22-first-projection-spike-findings.md` records initial findings.
- `docs/solutions/2026-05-23-pagination-latency-versioning-findings.md` records pagination/latency/versioning findings.

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
- `002` — `todos/002-done-p1-build-embedded-server-projection.md`
- `004` — `todos/004-done-p2-add-pagination-and-latency-cases.md`

Pending:

- `003` — `todos/003-pending-p3-evaluate-custom-persistent-store.md`

## Open Questions

Resolved so far:

- Server dependency: none; the embedded test server uses `Network.framework` plus tiny HTTP parsing.
- Conflict mechanism: explicit integer resource `version` fields.
- First conflict state location: `CDTask.isDirty`, `CDTask.lastSyncError`, and `CDTask.conflictState`.
- Pagination styles covered: cursor, offset, and numbered pages.
- Versioning split: API version, local model version, and per-resource optimistic concurrency version are separate concepts.

Still open:

- Should loading/error/conflict/completeness state stay on managed objects, move to separate sync records, or live in caller state as scenarios grow?
- Should local edits remain dirty flags on managed objects, or become separate pending-change entities / child-context units of work?
- After pagination and latency pressure tests, does a custom persistent store still seem worth exploring?

## Verification

Passing command:

```bash
cd experiments/core-data-rest-layer
swift test
```

Last verified 2026-05-23: 7 XCTest tests passed.

## Next Action

Write a small follow-up plan for sync/completeness metadata, then decide whether `todos/003-pending-p3-evaluate-custom-persistent-store.md` is still worth a spike.
