# SQLite vs In-Memory Benchmark Findings

**Date:** 2026-05-22  
**Experiment:** `core-data-graph-db`  
**Command:**

```bash
swift run -c release CoreDataGraphDBBenchmark --store both
```

## What Changed

The benchmark now supports:

```bash
swift run -c release CoreDataGraphDBBenchmark --store in-memory
swift run -c release CoreDataGraphDBBenchmark --store sqlite
swift run -c release CoreDataGraphDBBenchmark --store both
```

It also resets the managed object context after seeding and refetches the start/target nodes by label. This makes managed traversal exercise Core Data faulting/refetch behavior instead of only traversing already-live inserted objects.

SQLite stores are created under a temporary directory and cleaned up after each case.

## Release Benchmark Snapshot

Environment: local macOS Swift 6.2.3, release build.

```text
store,case,nodes,edges,seed_ms,snapshot_ms,managed_bfs_ms,snapshot_bfs_ms,managed_dijkstra_ms,snapshot_dijkstra_ms,path_weight
in-memory,small,100,180,1.731,0.419,0.183,0.024,0.257,0.110,59.000
in-memory,medium,625,1200,8.896,2.335,0.992,0.126,2.227,1.221,168.000
in-memory,large,2500,4900,34.875,10.021,4.021,0.508,12.593,8.893,343.000
sqlite,small,100,180,54.837,0.351,0.600,0.023,0.240,0.114,59.000
sqlite,medium,625,1200,156.600,1.881,3.369,0.196,2.397,1.433,168.000
sqlite,large,2500,4900,73.229,5.293,12.434,0.484,12.185,9.085,343.000
```

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
