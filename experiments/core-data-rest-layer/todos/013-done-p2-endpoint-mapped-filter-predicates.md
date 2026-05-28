---
status: done
priority: p2
issue_id: "013"
tags: [core-data, custom-store, predicates, filters]
dependencies: []
---

# Endpoint-mapped filter predicates

Design and implement a narrow custom-store predicate/filter spike that maps one deliberate Core Data fetch shape to a REST endpoint query instead of either rejecting every predicate or filtering locally.

Plan: `docs/plans/2026-05-26-endpoint-mapped-filter-predicates-plan.md`.

## Acceptance Criteria

- [x] `CDTask` fetches with `status == <String>` are supported as an explicit endpoint-mapped filter.
- [x] The REST client/store sends the status filter to task collection endpoints as a query parameter.
- [x] The embedded test server filters task collection responses by status.
- [x] Unsupported predicates still fail fast with `RESTIncrementalStoreError.unsupportedFetchShape` before HTTP.
- [x] Documentation records why this is a narrow endpoint mapping, not generic predicate translation.
