# First Projection Spike Findings

**Date:** 2026-05-22

## What shipped

A runnable Swift package now exercises:

```text
EmbeddedRESTServer -> URLSession RESTClient -> ProjectionSync -> Core Data context
```

The acceptance tests cover:

- syncing one project and two tasks over real local HTTP;
- normal Core Data fetches and `Project.tasks` / `Task.project` relationships;
- pushing a dirty local task edit through `PATCH /tasks/{id}`;
- preserving local attempted values and recording conflict metadata when the server has advanced the task version.

## Early learnings

- The local materialized projection is a good first shape. It keeps HTTP semantics explicit while still letting app-side code use Core Data identities, fetches, relationships, and change markers.
- Version conflicts should not be hidden inside `context.save()`. The sync layer records `isDirty`, `lastSyncError`, and `conflictState` so UI/app code can choose a reload, merge, or overwrite action deliberately.
- A programmatic Core Data model is enough for this spike and avoids introducing Xcode model-file conventions early.
- The embedded server is intentionally boring and dependency-free: `Network.framework`, in-memory state, JSON, and the three minimal endpoints.

## Next useful pressure tests

- [x] Add latency hooks to see whether loading state belongs on entities, separate sync records, or caller state.
- [x] Add pagination to test whether relationship completeness needs explicit metadata.
- [ ] Add cancellation hooks.
- [ ] Expand conflict metadata beyond a string if merge/resolve flows become interesting.

Follow-up findings: `2026-05-23-pagination-latency-versioning-findings.md`.
