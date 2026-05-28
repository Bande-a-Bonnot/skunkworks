# Endpoint-mapped Filter Predicates Findings

**Date:** 2026-05-26

## Summary

The custom REST incremental store now supports one deliberately mapped predicate shape: `CDTask` fetches where `status == <String>`. The store translates that Core Data predicate into the REST task collection query parameter `?status=<value>`.

This is endpoint mapping, not generic predicate translation.

## Implemented Shape

Supported:

```swift
let request = CDTask.fetchRequestSortedByTitle()
request.predicate = NSPredicate(format: "status == %@", "done")
let doneTasks = try context.fetch(request)
```

Mapped endpoint shape:

```text
GET /projects/{projectID}/tasks?status=done
```

The status query also flows through the existing cursor, offset, and numbered-page task collection helpers, so pagination remains endpoint-shaped.

## Guardrails

Unsupported predicates still fail before HTTP with `RESTIncrementalStoreError.unsupportedFetchShape`:

- non-`CDTask` predicates;
- non-equality operators;
- non-`status` key paths;
- compound predicates;
- non-string status constants.

The store does not evaluate unsupported predicates locally after fetching broad REST results. That keeps failures honest and avoids drifting into SQL-over-HTTP behavior.

## Server / Client Changes

- The embedded server filters `GET /projects/{projectID}/tasks` by optional `status` query item before sorting and pagination.
- The async `RESTClient` and blocking custom-store client both thread an optional status filter through task collection requests.
- Tests assert the query reaches the embedded server and that unsupported predicates still make no `/projects` request.

## Decision

A tiny whitelist can make app-facing Core Data fetches nicer without violating the experiment's main constraint. Predicate support should grow only when there is a real endpoint contract to map to.

## Next Ideas

- Consider `project.id == <UUID>` as a relationship-shaped task fetch if a caller needs to fetch tasks without first faulting `Project.tasks`.
- Consider compound `project.id == <UUID> AND status == <String>` only if the parser stays explicit and the endpoint remains `/projects/{id}/tasks?status=...`.
- Do not add local fallback filtering for unsupported predicates.
