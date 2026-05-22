---
status: pending
priority: p2
issue_id: "007"
tags: [benchmark, graph-fixtures]
dependencies: ["005"]
---

# Add Random Graph Fixtures

Extend benchmarks beyond sparse right/down grid graphs.

## Acceptance Criteria

- Add deterministic random graph generation with a seed.
- Include at least one sparse random graph and one denser random graph case.
- Ensure Dijkstra has a reachable target path or report unreachable cases explicitly.
- Document how random graph shape changes managed/prefetched/snapshot traversal behavior.
