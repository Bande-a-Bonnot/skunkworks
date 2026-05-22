# SQLite Store Benchmark Plan

**Date:** 2026-05-22  
**Status:** completed 2026-05-22  
**Experiment:** `experiments/core-data-graph-db/`

## Goal

Extend the graph benchmark beyond `NSInMemoryStoreType` by comparing an in-memory Core Data store with a SQLite-backed Core Data store.

## Scope

- Add `GraphStore` support for an optional persistent store URL.
- Extend `CoreDataGraphDBBenchmark` with `--store in-memory|sqlite|both`.
- Use temporary SQLite files and clean them up after benchmark runs.
- Reset the managed object context after seeding and refetch start/target nodes by label so managed traversal measures fault-backed access rather than only already-live objects.
- Document benchmark results.

## Acceptance Criteria

- `swift test` passes.
- `swift run -c release CoreDataGraphDBBenchmark --store both` runs successfully.
- Output identifies store type per row.
- Findings are captured in `docs/solutions/`.
- Local/root todos and handoffs are updated.
