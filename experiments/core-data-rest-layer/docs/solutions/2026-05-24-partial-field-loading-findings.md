# Partial Field Loading Findings

**Date:** 2026-05-24

## Summary

The custom `NSIncrementalStore` can represent sparse REST list responses, but property access should not silently fetch detail-only fields. The spike keeps list objects explicit by storing a loaded field marker on `CDTask` and requiring an explicit detail refresh before app code treats `notes` as authoritative.

## Implemented Shape

- `RemoteTask.notes` is a detail-only nullable field.
- Task list endpoints (`GET /projects/{id}/tasks`) return summary tasks that omit the `notes` key.
- Task detail endpoint (`GET /tasks/{id}`) returns the full task and includes `notes`, even when the value is JSON `null`.
- `RemoteTask` decodes whether the `notes` key was present into `isDetailLoaded`.
- `CDTask.loadedFields` records whether only `summary` fields or `summary,notes` have been loaded.
- `RESTCoreDataStack.loadTaskDetails(for:)` explicitly calls the detail endpoint, updates the store cache, and refreshes the managed object.

## Outcome

This makes three states observable to app code:

1. `loadedFields == "summary"` and `notes == nil` means notes are not loaded yet.
2. `loadedFields == "summary,notes"` and `notes == nil` means the server explicitly returned null notes.
3. `loadedFields == "summary,notes"` and `notes == ""` means the server returned an empty string.

## Decision

Partial field loading is viable only if field completeness is explicit. Hiding detail fetches behind ordinary optional property access would make `nil` ambiguous and would introduce surprising synchronous network work from what looks like local object graph traversal.

Prefer explicit refresh/load APIs for sparse REST fields. Relationship faults may still perform REST work because relationship loading is already visible as graph traversal; scalar field access should remain local once the object node has been materialized.

## Remaining Risks

- `loadedFields` as a comma-delimited string is a spike-level representation. A real library should probably use generated constants or a separate sync/detail-state entity.
- Explicit refresh currently invalidates the managed object and reloads from the store cache; callers should avoid this on objects with unsaved local edits.
- Different endpoints might have multiple projections, not just `summary` vs `notes`, which would need a more structured completeness model.
