# Endpoint-mapped Filter Predicates Plan

**Date:** 2026-05-26

## Goal

Add the smallest useful predicate/filter support to `RESTIncrementalStore` without turning the custom store into SQL-over-HTTP.

The specific spike: support `CDTask` fetch requests whose predicate is exactly a status equality filter, and map that to the task collection REST endpoint as `?status=<value>`.

## Why This Shape

Task status is a plausible screen-level server filter: apps commonly show open/done tasks, and REST APIs commonly expose this as an endpoint query parameter. It is narrow enough to be explicit and testable.

This remains different from generic predicate translation:

- no arbitrary key paths;
- no compound predicates yet;
- no local post-filtering to make unsupported shapes appear to work;
- unsupported predicates still fail before HTTP.

## Endpoint Contract

Existing endpoint:

```text
GET /projects/{projectID}/tasks
```

Add query support:

```text
GET /projects/{projectID}/tasks?status=open
```

Pagination query parameters may coexist with `status` later; for this spike, the same status filter should flow through the existing pagination helpers when present.

## Implementation Steps

1. Add a tiny internal task filter representation, initially only `statusEquals(String)`.
2. Parse `NSPredicate` only for direct equality comparisons where one side is key path `status` and the other side is a string constant.
3. Update fetch validation so:
   - nil predicates remain supported;
   - `CDTask.status == <String>` is supported;
   - every other predicate fails with `unsupportedFetchShape` before HTTP.
4. Thread the task filter through `RESTIncrementalStore` task fetch helpers and `BlockingRESTClient`.
5. Add matching optional status filtering to the async `RESTClient` for consistency with the older projection path.
6. Teach the embedded server to honor `status` on task collection endpoints before sorting/pagination.
7. Add tests proving supported status predicates hit the endpoint query and unsupported predicates still fail fast.

## Non-goals

- Project predicates.
- Relationship key-path predicates such as `project.id == ...`.
- Compound `AND` / `OR` predicates.
- Local in-memory predicate evaluation.
- Fetch limits/offsets/batches; those remain rejected.

## Verification

```bash
cd experiments/core-data-rest-layer
swift test
```
