---
status: pending
priority: p2
issue_id: "004"
tags: [benchmark, core-data, sqlite]
dependencies: ["001", "002", "003"]
---

# Compare SQLite-Backed Store

Extend the benchmark to compare `NSInMemoryStoreType` with a SQLite-backed persistent store.

## Acceptance Criteria

- Benchmark can run against both in-memory and SQLite stores.
- SQLite store uses a temporary experiment-local path and cleans up after itself.
- Results are documented in `docs/solutions/`.
- README and handoff are updated with the new command/options.
