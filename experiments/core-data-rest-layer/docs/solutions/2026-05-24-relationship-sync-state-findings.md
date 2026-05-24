# Relationship Sync State Findings

**Date:** 2026-05-24

## What changed

Added `CDRemoteRelationshipState`, a managed entity synthesized by the `RESTIncrementalStore` path.

Current fields:

- `ownerEntityName`
- `ownerRemoteID`
- `relationshipName`
- `paginationMode`
- `isComplete`
- `fetchedCount`
- `totalCount`
- `nextCursor`
- `lastLoadedAt`
- `lastError`

When `Project.tasks` relationship faulting walks REST pages, the store records a state row keyed by `CDProject:<projectID>:tasks`.

## Tested behavior

- Before relationship faulting, there is no relationship state row.
- Successful paginated relationship loading writes a complete state:
  - `paginationMode = cursor(limit:2)` in the covered test;
  - `isComplete = true`;
  - `fetchedCount = 5`;
  - `totalCount = 5`;
  - `lastLoadedAt` set;
  - `lastError = nil`.
- Failed relationship loading writes an incomplete state:
  - `isComplete = false`;
  - counts are zero;
  - `lastError` captures the thrown REST/store error.

## Finding

This does make REST-backed relationship faults more inspectable from ordinary Core Data code. App/UI code can now ask a Core Data question — “what do we know about this relationship’s remote completeness?” — without consulting separate app-side state.

But it also proves the cost: the moment relationship faulting crosses a paginated REST boundary, Core Data needs non-domain sync metadata. That is not necessarily bad, but it means a custom REST store is not “REST made invisible”; it is a store plus a visible remote-state model.

## Next pressure points

- Make relationship state queryable by convenience APIs instead of raw fetch predicates.
- Track partial progress for cursor/offset/page walks instead of only final success/failure.
- Decide whether `totalCount` should mean known server total or just fetched count when the API does not provide a total.
- Explore partial object field loading state, not just relationship loading state.
