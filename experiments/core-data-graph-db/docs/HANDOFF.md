# Core Data Graph Database Handoff

**URN:** `skunkworks::local::experiment::core-data-graph-db::handoff::019e4c87-dd7e-75ef-a7e6-feb136eb2d9c`  
**Last updated:** 2026-05-22  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on `experiments/core-data-graph-db/`.

---

## Purpose

Explore whether Core Data can serve as a useful app-local graph database substrate: nodes, first-class weighted edges, relationship traversal, and algorithms such as BFS and Dijkstra.

## Current State

First runnable spike and benchmark follow-ups are complete.

Implemented:

- Swift package at `experiments/core-data-graph-db/`.
- Programmatic Core Data model.
- `GraphNode` and first-class weighted directed `GraphEdge` entities.
- In-memory and SQLite-backed `GraphStore` support.
- Fixture and grid graph seeding.
- BFS and Dijkstra over live managed-object relationships.
- BFS and Dijkstra over value-type adjacency snapshots.
- Benchmark comparisons for:
  - no-prefetch managed traversal;
  - relationship-prefetched managed traversal;
  - snapshot traversal.
- Unit tests for model creation, BFS, Dijkstra, unreachable targets, grid seeding, and SQLite refetch.
- Readable benchmark table output by default; `--format csv` for machine-readable output.

Key files:

- `Package.swift`
- `Sources/CoreDataGraphDB/`
- `Sources/CoreDataGraphDBBenchmark/main.swift`
- `Tests/CoreDataGraphDBTests/`
- `docs/plans/2026-05-21-core-data-graph-db-first-spike-plan.md`
- `docs/plans/2026-05-22-sqlite-store-benchmark-plan.md`
- `docs/plans/2026-05-22-prefetch-benchmark-plan.md`
- `docs/plans/2026-05-22-experimental-spm-library-api-plan.md` — parked future direction for turning the spike into a reusable SPM library.
- `docs/solutions/2026-05-21-first-spike-benchmark-findings.md`
- `docs/solutions/2026-05-22-sqlite-vs-in-memory-benchmark-findings.md`
- `docs/solutions/2026-05-22-relationship-prefetch-benchmark-findings.md`

## Working Direction

Current hypothesis:

```text
Core Data is useful as a persistent object graph / identity / relationship-integrity substrate.
Relationship prefetching makes managed traversal viable.
Algorithmic hot paths should probably run over value snapshots.
```

SQLite fault-backed traversal is expensive without prefetch. Prefetching `outgoingEdges` and `outgoingEdges.target` dramatically improves managed traversal on SQLite, but snapshot traversal remains the fastest and simplest algorithm execution path.

## Local Todos

Done:

- `001` — `todos/001-done-p1-write-first-spike-plan.md`
- `002` — `todos/002-done-p1-build-core-data-graph-harness.md`
- `003` — `todos/003-done-p1-implement-bfs-and-dijkstra.md`
- `004` — `todos/004-done-p2-compare-sqlite-backed-store.md`
- `005` — `todos/005-done-p2-prefetch-relationship-traversal-benchmark.md`

Pending:

- `006` — `todos/006-pending-p2-add-repeated-benchmark-runs.md`
- `007` — `todos/007-pending-p2-add-random-graph-fixtures.md`

Deferred:

- `008` — `todos/008-deferred-p2-experimental-spm-library-api.md`

## Verification

Last verified on 2026-05-22:

```bash
cd experiments/core-data-graph-db
swift test
swift run -c release CoreDataGraphDBBenchmark --store both
swift run -c release CoreDataGraphDBBenchmark --store both --format csv
```

All passed.

Release benchmark snapshot:

| Store     | Case   | Nodes | Edges | Seed ms | Snapshot build ms | Prefetch ms | BFS managed ms | BFS prefetched ms | BFS snapshot ms | Dijkstra managed ms | Dijkstra prefetched ms | Dijkstra snapshot ms | Path weight |
| --------- | ------ | ----: | ----: | ------: | ----------------: | ----------: | -------------: | ----------------: | --------------: | ------------------: | ---------------------: | -------------------: | ----------: |
| in-memory | small  |   100 |   180 |   1.733 |             0.404 |       0.461 |          0.478 |             0.389 |           0.021 |               0.602 |                  0.237 |                0.108 |      59.000 |
| in-memory | medium |   625 |  1200 |   9.053 |             2.381 |       2.739 |          2.926 |             2.475 |           0.123 |               3.973 |                  2.102 |                1.267 |     168.000 |
| in-memory | large  |  2500 |  4900 |  35.132 |             9.442 |      10.839 |         11.113 |            10.412 |           0.519 |              20.488 |                 12.603 |                9.076 |     343.000 |
| sqlite    | small  |   100 |   180 | 125.990 |             0.418 |       0.819 |          2.265 |             0.191 |           0.025 |               2.132 |                  0.235 |                0.118 |      59.000 |
| sqlite    | medium |   625 |  1200 |  49.759 |             1.897 |       3.161 |         12.315 |             1.072 |           0.118 |              15.659 |                  1.821 |                1.175 |     168.000 |
| sqlite    | large  |  2500 |  4900 |  78.737 |             7.205 |      11.120 |         52.327 |             5.007 |           0.514 |              61.347 |                 13.027 |                9.230 |     343.000 |

## Open Questions

- What graph sizes make snapshot build cost meaningful?
- How do denser/random graph shapes change the managed/prefetched/snapshot tradeoff?
- Should the next algorithm be connected components, cycle detection, topological sort, or A*?
- Should benchmarks report repeated-run median/p95 before drawing stronger conclusions?

## Next Action

Recommended next step: switch to `core-data-rest-layer` and write its first spike plan. The SPM library API idea is documented and intentionally parked in `docs/plans/2026-05-22-experimental-spm-library-api-plan.md`.
