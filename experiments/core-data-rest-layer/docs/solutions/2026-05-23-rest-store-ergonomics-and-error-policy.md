# REST Store Ergonomics and Error Policy

**Date:** 2026-05-23

## Error policy

The custom store now uses `RESTIncrementalStoreError` as the public error surface. It conforms to `CustomNSError` so callers that receive bridged `NSError`s still get stable diagnostics:

- domain: `CoreDataRESTLayer.RESTIncrementalStoreError`
- code: stable per error case
- `HTTPStatusCode` / `ResponseBody` for non-conflict HTTP failures
- remote task details for conflicts

Current policy:

- Fetch HTTP failures throw from `context.fetch(...)`.
- Relationship-fault HTTP failures throw from the store hook. Plain Swift property access (`project.tasks`) is still awkward because Objective-C fault firing does not provide a nice `throws` boundary; app code should use explicit background prefetch/load operations when it needs graceful UI recovery.
- Save conflicts both annotate the local attempted object and throw `RESTIncrementalStoreError.conflict(remote:)`.
- Non-conflict save HTTP failures throw `RESTIncrementalStoreError.httpStatus` and do not silently mutate object sync metadata.

## Execution policy

`NSIncrementalStore` methods are synchronous. The store currently uses a blocking `URLSession` wrapper because Core Data calls `execute`, `newValuesForObject`, `newValue(forRelationship:)`, and save handling synchronously.

Recommended app-facing policy:

1. Treat any Core Data operation against this store as potentially blocking network I/O.
2. Use private-queue contexts for fetches, relationship preloading, and saves.
3. Avoid UI code that directly touches unloaded relationships.
4. Provide explicit app-level load operations that run on a background context, then hand object IDs or snapshots back to UI.
5. Do not promise true cancellation yet. Cancellation can be added around the app-level operation, but once Core Data has entered a synchronous store method, cancellation is cooperative at best unless the blocking client is redesigned.

`RESTCoreDataStack.makeBackgroundContext()` exists as the first helper for this policy.

## Pagination/completeness metadata evaluation

Relationship faulting can now walk cursor, offset, or numbered-page endpoints, but it eagerly loads all pages and only returns a relationship value after the walk completes.

Options for completeness metadata:

1. **Store metadata**
   - Good for global configuration such as selected pagination strategy.
   - Bad for per-project relationship state because store metadata is coarse and not query-friendly.

2. **Managed sync-state entities**
   - Best fit if app/UI needs to ask: “is `Project.tasks` complete?”, “what was the last cursor?”, “when did this fail?”
   - Downside: introduces non-domain entities into the Core Data model and the store must synthesize/update them.

3. **External app state**
   - Keeps the Core Data model purer.
   - Harder to keep consistent with object faults and multiple contexts.

Current recommendation: add managed sync-state entities if this continues. A possible entity:

```text
CDRemoteRelationshipState
- ownerEntityName
- ownerRemoteID
- relationshipName
- paginationMode
- isComplete
- nextCursor
- fetchedCount
- totalCount
- lastLoadedAt
- lastError
```

That keeps relationship data in `Project.tasks` while representing remote completeness as first-class Core Data state.
