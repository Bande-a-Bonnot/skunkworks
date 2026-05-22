---
status: done
priority: p2
issue_id: "005"
tags: [benchmark, core-data, prefetching]
dependencies: ["001", "002", "003"]
completed: 2026-05-22
---

# Prefetch Relationship Traversal Benchmark

Measure whether Core Data relationship prefetching changes managed-object traversal performance.

## Acceptance Criteria

- [x] Add a benchmark mode or separate benchmark case with `relationshipKeyPathsForPrefetching` where applicable.
- [x] Compare managed traversal with and without prefetching.
- [x] Document whether prefetching matters for in-memory and/or SQLite-backed stores.

## Result

Benchmark now compares no-prefetch managed traversal, prefetched managed traversal, and snapshot traversal after separate context resets. Findings are documented in `docs/solutions/2026-05-22-relationship-prefetch-benchmark-findings.md`.
