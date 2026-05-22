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
- Benchmark executable comparing managed traversal with snapshot traversal across in-memory and SQLite-backed stores. Default output is a readable Markdown-style table; `--format csv` is available for machine-readable output.

Key files:

- `Package.swift`
- `Sources/CoreDataGraphDB/`
- `Sources/CoreDataGraphDBBenchmark/main.swift`
- `Tests/CoreDataGraphDBTests/`
- `docs/plans/2026-05-21-core-data-graph-db-first-spike-plan.md`
- `docs/solutions/2026-05-21-first-spike-benchmark-findings.md`
- `docs/solutions/2026-05-22-sqlite-vs-in-memory-benchmark-findings.md`

## Working Direction

Current hypothesis after the first benchmark:

```text
Core Data is useful as a persistent object graph / identity / relationship-integrity substrate.
Algorithmic hot paths should probably run over value snapshots.
```

Snapshot traversal is cleaner and faster in the release benchmarks. Managed-object traversal is still pleasant and adequate for small graphs. SQLite primarily changes write/seed cost and fault-backed relationship traversal; snapshot algorithm runtime is mostly store-agnostic after the snapshot exists.

## Local Todos

Done:

- `001` — `todos/001-done-p1-write-first-spike-plan.md`
- `002` — `todos/002-done-p1-build-core-data-graph-harness.md`
- `003` — `todos/003-done-p1-implement-bfs-and-dijkstra.md`

Pending:

- `005` — `todos/005-pending-p2-prefetch-relationship-traversal-benchmark.md`

## Verification

Last verified on 2026-05-22:

```bash
cd experiments/core-data-graph-db
swift test
swift run CoreDataGraphDBBenchmark --store both
swift run -c release CoreDataGraphDBBenchmark --store both
swift run -c release CoreDataGraphDBBenchmark --store both --format csv
```

All passed.

Release benchmark snapshot:

| Store     | Case   | Nodes | Edges | Seed ms | Snapshot ms | BFS managed ms | BFS snapshot ms | Dijkstra managed ms | Dijkstra snapshot ms | Path weight |
| --------- | ------ | ----: | ----: | ------: | ----------: | -------------: | --------------: | ------------------: | -------------------: | ----------: |
| in-memory | small  |   100 |   180 |   1.713 |       0.418 |          0.171 |           0.020 |               0.254 |                0.110 |      59.000 |
| in-memory | medium |   625 |  1200 |   9.249 |       2.304 |          0.960 |           0.119 |               2.058 |                1.193 |     168.000 |
| in-memory | large  |  2500 |  4900 |  33.294 |       9.595 |          3.783 |           0.650 |              13.153 |                8.472 |     343.000 |
| sqlite    | small  |   100 |   180 |  43.671 |       0.331 |          0.536 |           0.021 |               0.232 |                0.107 |      59.000 |
| sqlite    | medium |   625 |  1200 |  34.420 |       1.633 |          2.949 |           0.122 |               1.994 |                1.150 |     168.000 |
| sqlite    | large  |  2500 |  4900 |  68.089 |       5.371 |         12.761 |           0.498 |              12.383 |                8.952 |     343.000 |

## Open Questions

- Does relationship prefetching materially improve managed traversal?
- What graph sizes make snapshot build cost meaningful?
- Should the next algorithm be connected components, cycle detection, topological sort, or A*?

## Next Action

Run the relationship-prefetch benchmark follow-up (`todo 005`).
