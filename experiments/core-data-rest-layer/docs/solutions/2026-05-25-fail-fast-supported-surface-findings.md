# Fail-Fast Supported Surface Findings

**Date:** 2026-05-25

## Summary

The custom REST incremental store now rejects unsupported Core Data surface area explicitly instead of silently returning broad results or ignoring save operations.

## Implemented Shape

- Added typed `RESTIncrementalStoreError.unsupportedFetchShape(entity:reason:)`.
- Added typed `RESTIncrementalStoreError.unsupportedSaveShape(entity:operation:)`.
- Bridged both cases through `CustomNSError` with stable codes and userInfo keys.
- Fetch execution now validates the narrow supported shape before any HTTP call:
  - managed-object results only;
  - no predicates;
  - no fetch limits, offsets, or batch sizes;
  - no partial property fetches;
  - simple key sort descriptors only.
- Save execution now validates the narrow supported write surface before mutating local caches or sending HTTP:
  - `CDTask` updates remain supported and map to `PATCH /tasks/{id}`;
  - `CDPendingTaskChange` insert/update/delete remains local-only and supported;
  - domain inserts/deletes and non-supported sync-state mutations fail fast.

## Tested Behavior

- Predicate-backed task fetches throw `unsupportedFetchShape` and do not call `/projects`.
- Fetch limits throw `unsupportedFetchShape` and do not call `/projects`.
- Count-result fetch shape throws `unsupportedFetchShape` when run through the store boundary.
- Inserting a `CDProject` throws `unsupportedSaveShape` and does not call REST.
- Deleting a task graph fails before any task `PATCH` is attempted.
- Existing supported fetches, simple sorts, relationship faults, direct task saves, pending-change flows, projection tests, and HTTP error tests still pass.

## Decision

Keep the store honest and narrow. If a Core Data feature is not deliberately mapped to an endpoint-shaped REST operation, throw a typed error at the boundary rather than approximating SQL semantics in memory.

## Remaining Risks

- Sort support is intentionally small and in-memory over the endpoint result; it is not a generic server sort translator.
- Predicate/filter support remains a future explicit design task, not an accidental local filter.
- Core Data may do internal relationship/delete bookkeeping before the save reaches the store, so callers should rely on the typed store error rather than exact graph mutation ordering.
