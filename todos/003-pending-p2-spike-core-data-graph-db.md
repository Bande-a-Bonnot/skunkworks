---
status: pending
priority: p2
issue_id: "003"
tags: [core-data, graph, swift, algorithms]
dependencies: []
---

# Spike Core Data Graph Database

Create the first runnable spike for `experiments/core-data-graph-db/`.

## Acceptance Criteria

- A minimal Swift harness exists in the experiment directory.
- The harness models `GraphNode` and `GraphEdge` in Core Data.
- It seeds a small weighted graph.
- It implements at least BFS and Dijkstra.
- It records whether traversal over managed objects or a value snapshot feels better.

## Notes

This does not need to compete with real graph databases. The target is app-local graph ergonomics and Core Data behavior under graph-shaped access.
