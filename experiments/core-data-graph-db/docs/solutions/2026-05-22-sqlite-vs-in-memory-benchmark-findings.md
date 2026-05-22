# SQLite vs In-Memory Benchmark Findings

**Date:** 2026-05-22  
**Experiment:** `core-data-graph-db`  
**Command:**

```bash
swift run -c release CoreDataGraphDBBenchmark --store both
```

Use CSV output for scripts/spreadsheets:

```bash
swift run -c release CoreDataGraphDBBenchmark --store both --format csv
```

## What Changed

The benchmark now supports:

```bash
swift run -c release CoreDataGraphDBBenchmark --store in-memory
swift run -c release CoreDataGraphDBBenchmark --store sqlite
swift run -c release CoreDataGraphDBBenchmark --store both
swift run -c release CoreDataGraphDBBenchmark --store both --format csv
```

Default output is a readable Markdown-style table. `--format csv` preserves machine-readable output.

It also resets the managed object context after seeding and refetches the start/target nodes by label. This makes managed traversal exercise Core Data faulting/refetch behavior instead of only traversing already-live inserted objects.

SQLite stores are created under a temporary directory and cleaned up after each case.

## Release Benchmark Snapshot

Environment: local macOS Swift 6.2.3, release build.

| Store     | Case   | Nodes | Edges | Seed ms | Snapshot ms | BFS managed ms | BFS snapshot ms | Dijkstra managed ms | Dijkstra snapshot ms | Path weight |
| --------- | ------ | ----: | ----: | ------: | ----------: | -------------: | --------------: | ------------------: | -------------------: | ----------: |
| in-memory | small  |   100 |   180 |   1.713 |       0.418 |          0.171 |           0.020 |               0.254 |                0.110 |      59.000 |
| in-memory | medium |   625 |  1200 |   9.249 |       2.304 |          0.960 |           0.119 |               2.058 |                1.193 |     168.000 |
| in-memory | large  |  2500 |  4900 |  33.294 |       9.595 |          3.783 |           0.650 |              13.153 |                8.472 |     343.000 |
| sqlite    | small  |   100 |   180 |  43.671 |       0.331 |          0.536 |           0.021 |               0.232 |                0.107 |      59.000 |
| sqlite    | medium |   625 |  1200 |  34.420 |       1.633 |          2.949 |           0.122 |               1.994 |                1.150 |     168.000 |
| sqlite    | large  |  2500 |  4900 |  68.089 |       5.371 |         12.761 |           0.498 |              12.383 |                8.952 |     343.000 |

## Initial Read

- SQLite seed/write cost is visibly higher than in-memory, as expected.
- Snapshot traversal remains fast and nearly store-agnostic once the snapshot exists.
- SQLite snapshot build was not worse in this run and was actually faster than in-memory on larger cases. Treat this as measurement noise / Core Data implementation detail until repeated runs exist.
- Managed BFS over SQLite is slower than in-memory after context reset, which fits the faulting/relationship-loading expectation.
- Managed Dijkstra is close between stores for this grid shape because the algorithm does less exhaustive relationship traversal than BFS and both versions keep frontier node references.

## Updated Hypothesis

Core Data's store choice matters most for:

```text
write/seed cost + fault-backed relationship traversal
```

Once graph data is snapshotted into value adjacency lists, algorithm runtime is mostly decoupled from whether the backing store was in-memory or SQLite.

## Caveats

- The benchmark is single-run and not statistically rigorous.
- Grid graphs are structured and sparse; denser/random graphs may behave differently.
- No relationship prefetching is measured yet.
- SQLite startup/setup costs can dominate small cases.

## Next Follow-Up

Measure relationship prefetching for managed traversal, especially SQLite-backed BFS.
