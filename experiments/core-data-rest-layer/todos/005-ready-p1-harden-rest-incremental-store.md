---
status: ready
priority: p1
issue_id: "005"
tags: [core-data, custom-store, rest]
dependencies: ["003"]
---

# Harden REST Incremental Store

Continue the real Core Data-over-REST path: `NSIncrementalStore` as the REST-backed persistent store.

## Acceptance Criteria

- Move projection-layer code/docs out of the critical path or mark clearly as non-target.
- Add conflict handling for `context.save()` when `PATCH /tasks/{id}` returns stale-version conflict.
- Decide how HTTP errors surface from fetches, relationship faults, and saves.
- Add pagination behavior to relationship faulting, not projection sync.
- Document limitations of synchronous Core Data store APIs over async HTTP.
