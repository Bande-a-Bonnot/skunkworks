# Review: `experiments/core-data-rest-layer`

## 1. Executive verdict

Successful conceptual spike. The implementation meets the core brief: it proves Core Data can front a tiny REST API via `NSIncrementalStore`, with real HTTP, relationships, versioned saves, conflicts, pagination, errors, and explicit partial-loading metadata.

It is not production-ready and should not graduate yet. The strongest outcome is the documented architectural finding: Core Data is useful as an object graph/unit-of-work layer, but REST loading/completeness/conflict semantics must remain explicit.

I did **not** run `swift test` to respect the read-only/no-writes review constraint. The handoff records 20 tests passing on 2026-05-24.

## 2. Original brief/goals as understood

The experiment started as:

- build a small Swift package;
- use an embedded REST server on `127.0.0.1:0`;
- model `Project` and `Task`;
- fetch remote resources through HTTP;
- expose them through Core Data fetches/relationships;
- push local edits with optimistic version conflicts;
- document where Core Data helps or fights REST.

The brief then intentionally pivoted from “local materialized projection” to the more interesting target:

```text
NSFetchRequest / relationship fault / context.save()
    -> NSIncrementalStore
    -> REST API
```

## 3. Goal coverage matrix

| Goal | Evidence | Status |
|---|---|---|
| Swift package scoped to experiment | `Package.swift` defines `CoreDataRESTLayer`, `CoreDataRESTLayerTestServer`, tests | Met |
| Embedded real HTTP server | `EmbeddedRESTServer.swift`, Network.framework, random port, JSON/status codes | Met |
| Minimal Project/Task REST domain | `RemoteModels.swift`, `CoreDataStack.swift` | Met |
| Core Data model with relationships | `CDProject`, `CDTask`, inverse `tasks/project` relationships | Met |
| Projection-sync first spike | `ProjectionSync.swift`, projection tests retained | Met / historical |
| Custom persistent store target | `RESTIncrementalStore.swift`, `RESTCoreDataStack` | Met for tiny domain |
| Fetch projects via Core Data -> REST | `execute` maps `CDProject` fetch to `GET /projects`; tested | Met |
| Relationship fault -> REST | `newValue(forRelationship:)` maps `Project.tasks` to `GET /projects/{id}/tasks`; tested | Met |
| Save task edit -> REST PATCH | `executeSave` maps updated `CDTask` to `PATCH /tasks/{id}`; tested | Met |
| Conflict handling | `RESTIncrementalStoreError.conflict`, object metadata mutation; tested | Met |
| Pagination pressure | cursor/offset/page strategies in client/store/server; tests | Met |
| Explicit relationship completeness | `CDRemoteRelationshipState` synthesized on load/failure | Mostly met |
| Partial field loading | `RemoteTask.isDetailLoaded`, `CDTask.loadedFields`, explicit `loadTaskDetails` | Mostly met |
| Typed error surface | `RESTIncrementalStoreError: CustomNSError`; tests for HTTP errors | Met |
| Background execution policy | `makeBackgroundContext()` and one test | Partial |
| Predicate/sort/filter translation | Fetch shapes are narrow; predicates/fetch limits mostly ignored | Partial / intentionally limited |
| Cancellation/timeouts/rate limits/eventual consistency | Question bank/docs only | Not covered |
| Avoid generic REST ORM | Store supports narrow endpoint-shaped cases only | Met |

## 4. Implementation strengths

- Clean experiment containment under `experiments/core-data-rest-layer`.
- Real HTTP boundary instead of fixtures.
- Strong acceptance tests proving Core Data operations hit REST endpoints.
- The custom store path is concrete, not just documented.
- Conflict, HTTP error, pagination, and partial-field semantics are explicit.
- Good documentation trail: plan, projection findings, custom-store findings, ergonomics/error policy, relationship state, partial fields, synthesis.
- The implementation correctly resists becoming a generic REST ORM.

## 5. Gaps/risks/mismatches against the brief

- `NSIncrementalStore` fetch handling is very narrow. Predicates, fetch limits, result types, and arbitrary sort descriptors are not supported or fail-fast guarded.
- Inserts/deletes are not supported, but save handling appears to ignore unsupported inserted/deleted objects rather than clearly throwing.
- Blocking REST calls use semaphores and `URLSession.shared`; there is no timeout/cancellation policy.
- Relationship faulting eagerly loads all pages; no partial progress or resumable cursor state.
- `CDRemoteRelationshipState` is synthesized from in-memory store cache, not durable remote-state storage.
- `loadedFields` is a comma-delimited spike representation.
- `loadTaskDetails(for:)` refreshes with `mergeChanges: false`, which can discard unsaved local changes.
- Core Data features listed in the initial question bank — validation, undo/redo, merge policies, batch updates/deletes, rate limits, eventual consistency — remain mostly unexplored.

## 6. Test/verification assessment

Test coverage is strong for the spike level: 20 XCTest methods cover incremental-store fetch/fault/save, conflicts, HTTP errors, pagination styles, relationship state, partial detail loading, projection sync, latency, and version headers.

Main missing verification areas:

- unsupported fetch/save shapes fail clearly;
- insert/delete behavior;
- cancellation/timeouts;
- multi-context refresh/merge behavior;
- server deletion/404/stale-read scenarios;
- validation/undo/batch operations;
- partial-field transitions from loaded non-nil to remote nil.

## 7. Recommended next actions

1. Add fail-fast tests and errors for unsupported `NSFetchRequest` and save shapes.
2. Design pending-change entities or child-context edit flows instead of simple dirty flags.
3. Add async app-facing loader/writer APIs with background contexts, timeouts, and cancellation boundaries.
4. Replace `loadedFields` and conflict strings with structured metadata.
5. Track relationship pagination partial progress, not just final success/failure.
6. Add deletion/stale-read/rate-limit scenarios only if continuing toward production realism.

## 8. Continue, park, graduate, or archive?

**Park as a successful spike.** It achieved the original/evolved goals and produced useful findings. Do **not** graduate yet; continue only if the next phase is explicitly about production ergonomics: cancellation, pending changes, structured metadata, and fail-fast supported Core Data surface area.
