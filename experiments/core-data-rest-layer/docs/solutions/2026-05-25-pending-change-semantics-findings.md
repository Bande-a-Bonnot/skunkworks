# Pending-Change Semantics Findings

**Date:** 2026-05-25

## Summary

A separate pending-change entity is a better semantic fit than expanding dirty flags on `CDTask` when the custom REST store needs to distinguish remote truth from local write intent.

The spike keeps `CDTask` as the last accepted remote snapshot and adds `CDPendingTaskChange` as local-only write intent for task updates. This makes conflict and retry state queryable without overwriting either the remote snapshot or the user's attempted values.

## Implemented Shape

- Added `CDPendingTaskChange` with:
  - task identity and base version;
  - attempted `title` / `status` values;
  - changed fields;
  - lifecycle state: `pending`, `failed`, `conflicted`;
  - attempt count and timestamps;
  - last error;
  - remote conflict fields.
- Added `RESTCoreDataStack.stageTaskUpdate(for:title:status:)`.
- Added `RESTCoreDataStack.flushPendingTaskChanges()`.
- Added local-only pending-change cache support inside `RESTIncrementalStore`.
- Kept the older direct `CDTask` edit + `context.save()` path as a baseline behavior.

## Tested Behavior

- Staging a task update does not mutate `CDTask` and does not call `PATCH`.
- Flushing a pending change calls `PATCH /tasks/{id}` with pending values and the recorded base version.
- Successful flush updates the task cache/object to the remote response and removes the pending change.
- Conflict keeps the attempted values on `CDPendingTaskChange`, records remote current values there, and refreshes `CDTask` to the remote current snapshot.
- Non-conflict HTTP failure marks the pending change `failed` with retryable error metadata.
- Retrying a failed pending change can later apply successfully.
- Repeated staging for the same task coalesces into one pending change while preserving the original base version.

## Decision

Prefer this semantic split for future custom-store work:

```text
CDTask = last accepted remote snapshot
CDPendingTaskChange = local user intent + write lifecycle
```

Dirty flags on domain objects remain useful as a baseline and for very small demos, but they conflate remote data, local attempts, and sync lifecycle. Child contexts remain useful for edit forms, but they do not by themselves provide durable/queryable pending write state.

## Remaining Risks

- Pending changes are still stored in the in-memory custom-store cache, not durable storage.
- The API is task-update-only and stringly typed (`state`, `changedFields`) by design for the spike.
- UI code would need an overlay pattern if it wants to display pending attempted values over canonical `CDTask` snapshots.
- Direct edits to `CDTask` are still possible and still trigger the baseline PATCH-on-save path.
- `flushPendingTaskChanges()` is synchronous and inherits the existing `NSIncrementalStore` blocking-network caveat.

## Next Pressure Points

- Decide whether pending changes should become durable local storage if the experiment continues.
- Add a structured enum/generated constants for pending states and field names.
- Explore child-context edit forms that produce pending-change records rather than mutating canonical tasks.
- Add cancellation/timeout policy around explicit flush/load operations.
