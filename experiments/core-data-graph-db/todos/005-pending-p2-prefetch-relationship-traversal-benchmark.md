---
status: pending
priority: p2
issue_id: "005"
tags: [benchmark, core-data, prefetching]
dependencies: ["001", "002", "003"]
---

# Prefetch Relationship Traversal Benchmark

Measure whether Core Data relationship prefetching changes managed-object traversal performance.

## Acceptance Criteria

- Add a benchmark mode or separate benchmark case with `relationshipKeyPathsForPrefetching` where applicable.
- Compare managed traversal with and without prefetching.
- Document whether prefetching matters for in-memory and/or SQLite-backed stores.
