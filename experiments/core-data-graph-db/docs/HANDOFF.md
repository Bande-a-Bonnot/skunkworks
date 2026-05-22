# Core Data Graph Database Handoff

**URN:** `skunkworks::local::experiment::core-data-graph-db::handoff::019e4c87-dd7e-75ef-a7e6-feb136eb2d9c`  
**Last updated:** 2026-05-22  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on `experiments/core-data-graph-db/`.

---

## Purpose

Explore whether Core Data can serve as a useful app-local graph database substrate: nodes, first-class weighted edges, relationship traversal, and algorithms such as BFS and Dijkstra.

## Current State

First runnable spike is complete.

Implemented:

- Swift package at `experiments/core-data-graph-db/`.
- Programmatic Core Data model.
- `GraphNode` and first-class weighted directed `GraphEdge` entities.
- In-memory `GraphStore` with fixture and grid seeding.
- BFS over live managed-object relationships.
- BFS over value-type adjacency snapshots.
- Dijkstra over live managed-object relationships.
- Dijkstra over value-type adjacency snapshots.
- Unit tests for model creation, BFS, Dijkstra, unreachable targets, and grid seeding.
- Benchmark executable comparing managed traversal with snapshot traversal.

Key files:

- `Package.swift`
- `Sources/CoreDataGraphDB/`
- `Sources/CoreDataGraphDBBenchmark/main.swift`
- `Tests/CoreDataGraphDBTests/`
- `docs/plans/2026-05-21-core-data-graph-db-first-spike-plan.md`
- `docs/solutions/2026-05-21-first-spike-benchmark-findings.md`

## Working Direction

Current hypothesis after the first benchmark:

```text
Core Data is useful as a persistent object graph / identity / relationship-integrity substrate.
Algorithmic hot paths should probably run over value snapshots.
```

Snapshot traversal is cleaner and faster in the first release benchmark. Managed-object traversal is still pleasant and adequate for small graphs.

## Local Todos

Done:

- `001` — `todos/001-done-p1-write-first-spike-plan.md`
- `002` — `todos/002-done-p1-build-core-data-graph-harness.md`
- `003` — `todos/003-done-p1-implement-bfs-and-dijkstra.md`

Pending:

- `004` — `todos/004-pending-p2-compare-sqlite-backed-store.md`
- `005` — `todos/005-pending-p2-prefetch-relationship-traversal-benchmark.md`

## Verification

Last verified on 2026-05-22:

```bash
cd experiments/core-data-graph-db
swift test
swift run CoreDataGraphDBBenchmark
swift run -c release CoreDataGraphDBBenchmark
```

All passed.

Release benchmark snapshot:

```text
case,nodes,edges,snapshot_ms,managed_bfs_ms,snapshot_bfs_ms,managed_dijkstra_ms,snapshot_dijkstra_ms,path_weight
small,100,180,0.167,0.118,0.021,0.209,0.115,59.000
medium,625,1200,0.657,0.638,0.116,1.779,1.220,168.000
large,2500,4900,2.860,2.540,0.502,10.878,8.403,343.000
```

## Open Questions

- How do results change with a SQLite-backed store?
- Does relationship prefetching materially improve managed traversal?
- What graph sizes make snapshot build cost meaningful?
- Should the next algorithm be connected components, cycle detection, topological sort, or A*?

## Next Action

Pick one pending benchmark follow-up:

1. SQLite-backed store comparison (`todo 004`), or
2. relationship-prefetch benchmark (`todo 005`).
