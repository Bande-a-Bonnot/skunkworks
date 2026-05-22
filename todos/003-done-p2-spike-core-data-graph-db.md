---
status: done
priority: p2
issue_id: "003"
tags: [core-data, graph, swift, algorithms]
dependencies: []
completed: 2026-05-22
---

# Spike Core Data Graph Database

Create the first runnable spike for `experiments/core-data-graph-db/`.

## Acceptance Criteria

- [x] A minimal Swift harness exists in the experiment directory.
- [x] The harness models `GraphNode` and `GraphEdge` in Core Data.
- [x] It seeds a small weighted graph.
- [x] It implements at least BFS and Dijkstra.
- [x] It records whether traversal over managed objects or a value snapshot feels better.

## Result

Implemented a Swift package with tests and a release benchmark executable. Findings are in `experiments/core-data-graph-db/docs/solutions/2026-05-21-first-spike-benchmark-findings.md`.

## Notes

This does not need to compete with real graph databases. The target is app-local graph ergonomics and Core Data behavior under graph-shaped access.
