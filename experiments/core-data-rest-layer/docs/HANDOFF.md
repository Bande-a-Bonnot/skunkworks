# Core Data REST Layer Handoff

**URN:** `skunkworks::local::experiment::core-data-rest-layer::handoff::019e4c87-dd7e-708c-be24-fda71b3451b3`  
**Last updated:** 2026-05-24
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on `experiments/core-data-rest-layer/`.

---

## Purpose

Explore whether Core Data is useful as an object graph, identity map, validation, and change-tracking layer over REST-backed remote resources — not merely as a local SQLite/CloudKit persistence framework.

## Current State

A real custom-store spike exists and passes tests. The earlier projection-sync spike remains in code, but it is not the target architecture for this experiment.

Implemented package:

- `Package.swift`
- `Sources/CoreDataRESTLayer/RemoteModels.swift` — JSON domain models and shared JSON coding.
- `Sources/CoreDataRESTLayer/RESTClient.swift` — `URLSession` client for `GET /projects`, paginated `GET /projects/{projectID}/tasks`, and `PATCH /tasks/{taskID}`.
- `Sources/CoreDataRESTLayer/VersionMapping.swift` — explicit API version / local model version compatibility skeleton.
- `Sources/CoreDataRESTLayer/CoreDataStack.swift` — programmatic Core Data model with `CDProject` / `CDTask`, relationship, version, dirty, conflict metadata, and `CDRemoteRelationshipState`.
- `Sources/CoreDataRESTLayer/RESTIncrementalStore.swift` — `NSIncrementalStore` that maps Core Data fetches, relationship faults, task saves, and relationship sync-state synthesis to REST calls.
- `Sources/CoreDataRESTLayer/ProjectionSync.swift` — earlier pull projection path; keep as historical/baseline code, not the target architecture.
- `Sources/CoreDataRESTLayerTestServer/EmbeddedRESTServer.swift` — dependency-free `Network.framework` local HTTP server bound to `127.0.0.1:0`, with pagination and latency hooks.
- `Tests/CoreDataRESTLayerTests/CoreDataRESTLayerTests.swift` — acceptance tests for incremental-store fetch/fault/save, conflict/error behavior, background context helper, plus earlier projection, pagination, latency, and version-header tests.

Current docs:

- `README.md` describes the experiment, quick start, and first findings.
- `docs/initial-questions.md` captures conceptual/API/Core Data questions.
- `docs/plans/2026-05-22-core-data-rest-layer-first-spike-plan.md` defines the implemented first spike.
- `docs/solutions/2026-05-22-first-projection-spike-findings.md` records initial findings.
- `docs/solutions/2026-05-23-pagination-latency-versioning-findings.md` records pagination/latency/versioning findings.
- `docs/solutions/2026-05-23-rest-incremental-store-spike.md` records the custom-store pivot and current findings.
- `docs/solutions/2026-05-23-rest-store-ergonomics-and-error-policy.md` records error/execution/completeness recommendations.
- `docs/solutions/2026-05-24-relationship-sync-state-findings.md` records managed relationship-state findings.

## Working Direction

The target architecture is the custom persistent store path, not a conventional projection/sync layer:

```text
NSFetchRequest / relationship fault / context.save()
        -> RESTIncrementalStore
        -> embedded local REST server
```

Keep the embedded server bound to `127.0.0.1:0` in tests. Preserve the earlier projection code only as historical context; new work should harden `RESTIncrementalStore`.

## Local Todos

Done:

- `001` — `todos/001-done-p1-write-first-spike-plan.md`
- `002` — `todos/002-done-p1-build-embedded-server-projection.md`
- `003` — `todos/003-done-p3-evaluate-custom-persistent-store.md`
- `004` — `todos/004-done-p2-add-pagination-and-latency-cases.md`
- `005` — `todos/005-done-p1-harden-rest-incremental-store.md`
- `006` — `todos/006-done-p1-rest-store-ergonomics-and-errors.md`
- `007` — `todos/007-done-p2-add-relationship-sync-state-entity.md`

Ready:

- `008` — `todos/008-ready-p2-partial-object-field-loading.md`

## Open Questions

Resolved so far:

- Server dependency: none; the embedded test server uses `Network.framework` plus tiny HTTP parsing.
- Conflict mechanism: explicit integer resource `version` fields.
- First conflict state location: `CDTask.isDirty`, `CDTask.lastSyncError`, and `CDTask.conflictState`.
- Pagination styles covered: cursor, offset, and numbered pages.
- Versioning split: API version, local model version, and per-resource optimistic concurrency version are separate concepts.
- Custom store path is worthwhile; the projection path answered the wrong question.

Still open:

- Should loading/error/conflict/completeness state stay on managed objects, move to separate sync records, or live in caller state as scenarios grow?
- Should local edits remain dirty flags on managed objects, or become separate pending-change entities / child-context units of work?
- Can synchronous store methods be made cancellable enough for real app use?
- Can partial object/field loading be represented without surprising property access semantics?

## Verification

Passing command:

```bash
cd experiments/core-data-rest-layer
swift test
```

Last verified 2026-05-24: 19 XCTest tests passed.

## Next Action

Pick up `todos/008-ready-p2-partial-object-field-loading.md`: test partial field loading semantics in the custom-store path.
