# Pagination, Latency, and Versioning Findings

**Date:** 2026-05-23

## Pagination shapes exercised

The embedded server and client now exercise three common REST pagination styles for project tasks:

1. **Cursor** — client requests `limit` plus optional `cursor`; server returns `items` and `nextCursor`.
2. **Offset** — client requests `limit` plus `offset`; client continues while returned item count equals requested limit.
3. **Numbered pages** — client requests `page` plus `perPage`; server returns `page`, `perPage`, and `totalPages`.

`ProjectionSync` accepts `TaskPaginationStrategy` so the same Core Data projection can be filled from any of these wire contracts.

## What leaks above Core Data

Pagination cannot be safely hidden as just a relationship fault:

- Cursor pagination has an opaque continuation token; the projection layer must know whether a relationship is complete for a given cursor walk.
- Offset pagination is fragile under concurrent server inserts/deletes; returned count is a heuristic, not a durable completeness proof.
- Numbered pages are easiest to reason about when `totalPages` is present, but the total can still become stale between page fetches.

A future production shape likely needs explicit sync/completeness metadata, e.g. `TaskCollectionSyncState(projectID, paginationMode, isComplete, lastCursor, fetchedAt, error)`, instead of pretending `Project.tasks` alone represents remote truth.

## Latency

The embedded server can inject per-path latency. The first test only verifies deterministic delay, but the design implication is already clear: loading/cancellation state belongs in the sync caller or a sync-state entity, not on every `CDTask` row.

## API version vs model version vs resource version

Keep these separate:

- **Resource version** — per-resource optimistic concurrency (`RemoteTask.version` / `CDTask.version`). Used for stale-write conflict detection.
- **API version** — wire contract version (`APIVersion`). Sent by `RESTClient` as `X-API-Version`.
- **Local model version** — Core Data projection/schema version (`LocalModelVersion`). Exposed as `CoreDataStack.localModelVersion` and sent as `X-Local-Model-Version` for test visibility.

The current mapping is intentionally small:

```swift
APIModelVersionMapping.current == local model v1 reads API v1 and writes API v1
```

Future versions should grow this as an explicit compatibility table, for example: model v2 can read API v1/v2 but writes API v2 after local migration.
