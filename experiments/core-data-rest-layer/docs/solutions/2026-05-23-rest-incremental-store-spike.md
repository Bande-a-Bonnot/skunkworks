# REST Incremental Store Spike

**Date:** 2026-05-23

## Pivot

The local projection architecture is not the target for this experiment. It is normal sync/cache architecture and does not answer the interesting question.

The interesting question is whether Core Data itself can act as the REST facade:

```text
NSFetchRequest / relationship fault / context.save()
        -> NSIncrementalStore
        -> HTTP REST API
```

## What now works

Added `RESTIncrementalStore`, an `NSIncrementalStore` subclass, plus `RESTCoreDataStack`.

Current tested behavior:

- `context.fetch(CDProject.fetchRequestSortedByName())` calls `GET /projects` through the custom store.
- Reading `project.tasks` resolves the Core Data relationship fault by calling `GET /projects/{projectID}/tasks`.
- Reading `task.project` resolves through store-provided object IDs.
- Editing a managed `CDTask` and calling `context.save()` calls `PATCH /tasks/{taskID}`.
- The embedded server request counters prove those HTTP paths were hit by Core Data store operations, not by the projection sync layer.

## Important implementation notes

`NSIncrementalStore` is synchronous. The spike uses a blocking URLSession wrapper inside store methods. That is not polished, but it matches Core Data's synchronous store API and makes the impedance mismatch visible.

The custom store must provide a non-nil store URL, even though this REST store does not write a local file. Passing `nil` caused a trap before `loadMetadata()`.

`NSStoreTypeKey` metadata must match the registered store type. The working registered type is `RESTIncrementalStore`.

## Hardened behavior added

- `context.save()` stale-write conflicts now decode the server's `409` response, mark the `CDTask` with `isDirty`, `lastSyncError`, and `conflictState`, then throw `RESTIncrementalStoreError.conflict(remote:)`.
- Relationship faulting can now traverse cursor, offset, or numbered-page task endpoints by configuring `RESTCoreDataStack(baseURL:taskPagination:)`.
- Fetches, relationship faults, and saves surface HTTP/network problems as thrown store errors. This is the current explicit policy: Core Data operations do not hide REST failures in silent object state, except that save conflicts also annotate the attempted object for inspection.

## Current limitations

- Inserts/deletes are not supported.
- Pagination metadata is not persisted as Core Data state; relationship faulting eagerly walks all pages for the configured strategy.
- HTTP errors thrown from relationship faulting are synchronous Core Data errors, which is honest but awkward for UI ergonomics.
- The old projection sync path still exists in code as prior work, but it is not the target architecture.

## Next step

Explore whether this can be made app-ergonomic: background-context execution policy, typed error recovery, and persistent pagination/completeness metadata in the custom-store path.
