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

## Current limitations

- Conflict handling for `context.save()` is not mapped cleanly yet.
- Inserts/deletes are not supported.
- Relationship pagination currently exists in the server/client, but not in the incremental-store relationship fault path.
- HTTP errors currently surface as thrown store errors; this needs a deliberate app-facing policy.
- The old projection sync path still exists in code as prior work, but it is not the target architecture.

## Next step

Do `todos/005-ready-p1-harden-rest-incremental-store.md`.
