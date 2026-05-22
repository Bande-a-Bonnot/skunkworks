---
status: done
priority: p2
issue_id: "004"
tags: [benchmark, core-data, sqlite]
dependencies: ["001", "002", "003"]
completed: 2026-05-22
---

# Compare SQLite-Backed Store

Extend the benchmark to compare `NSInMemoryStoreType` with a SQLite-backed persistent store.

## Acceptance Criteria

- [x] Benchmark can run against both in-memory and SQLite stores.
- [x] SQLite store uses a temporary path and cleans up after itself.
- [x] Results are documented in `docs/solutions/`.
- [x] README and handoff are updated with the new command/options.

## Result

Added `--store in-memory|sqlite|both` to `CoreDataGraphDBBenchmark`; documented findings in `docs/solutions/2026-05-22-sqlite-vs-in-memory-benchmark-findings.md`.
