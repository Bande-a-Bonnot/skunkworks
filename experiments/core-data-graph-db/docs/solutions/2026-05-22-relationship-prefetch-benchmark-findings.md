# Relationship Prefetch Benchmark Findings

**Date:** 2026-05-22  
**Experiment:** `core-data-graph-db`  
**Command:**

```bash
swift run -c release CoreDataGraphDBBenchmark --store both
```

## What Changed

The benchmark now resets the Core Data context before each strategy so measurements do not warm each other:

1. managed traversal without prefetch;
2. managed traversal after fetching all nodes with `relationshipKeyPathsForPrefetching = ["outgoingEdges", "outgoingEdges.target"]`;
3. snapshot traversal after building a value adjacency list.

The benchmark reports prefetch cost separately as `Prefetch ms`.

## Release Benchmark Snapshot

Environment: local macOS Swift 6.2.3, release build.

| Store     | Case   | Nodes | Edges | Seed ms | Snapshot build ms | Prefetch ms | BFS managed ms | BFS prefetched ms | BFS snapshot ms | Dijkstra managed ms | Dijkstra prefetched ms | Dijkstra snapshot ms | Path weight |
| --------- | ------ | ----: | ----: | ------: | ----------------: | ----------: | -------------: | ----------------: | --------------: | ------------------: | ---------------------: | -------------------: | ----------: |
| in-memory | small  |   100 |   180 |   1.733 |             0.404 |       0.461 |          0.478 |             0.389 |           0.021 |               0.602 |                  0.237 |                0.108 |      59.000 |
| in-memory | medium |   625 |  1200 |   9.053 |             2.381 |       2.739 |          2.926 |             2.475 |           0.123 |               3.973 |                  2.102 |                1.267 |     168.000 |
| in-memory | large  |  2500 |  4900 |  35.132 |             9.442 |      10.839 |         11.113 |            10.412 |           0.519 |              20.488 |                 12.603 |                9.076 |     343.000 |
| sqlite    | small  |   100 |   180 | 125.990 |             0.418 |       0.819 |          2.265 |             0.191 |           0.025 |               2.132 |                  0.235 |                0.118 |      59.000 |
| sqlite    | medium |   625 |  1200 |  49.759 |             1.897 |       3.161 |         12.315 |             1.072 |           0.118 |              15.659 |                  1.821 |                1.175 |     168.000 |
| sqlite    | large  |  2500 |  4900 |  78.737 |             7.205 |      11.120 |         52.327 |             5.007 |           0.514 |              61.347 |                 13.027 |                9.230 |     343.000 |

## Initial Read

Relationship prefetching matters a lot for SQLite-backed managed traversal:

- SQLite large BFS: `52.327 ms` unmanaged/pure faulting vs `5.007 ms` after prefetch.
- SQLite large Dijkstra: `61.347 ms` unmanaged/pure faulting vs `13.027 ms` after prefetch.

For the in-memory store, prefetching is a modest improvement for traversal time, but the prefetch cost itself is comparable to snapshot build cost.

Snapshot traversal is still the fastest algorithm execution path by a large margin, especially BFS. Even when adding snapshot build cost, snapshot remains competitive with prefetch for these graph sizes and store types.

## Updated Hypothesis

Core Data managed traversal can be made much less bad with relationship prefetching, especially on SQLite-backed stores. However:

```text
prefetching makes managed traversal viable;
snapshotting still makes algorithm hot paths simpler and faster.
```

A practical Core Data graph engine probably wants both modes:

- managed-object traversal for small, app-shaped, identity-sensitive interactions;
- snapshot adjacency traversal for graph algorithms and repeated queries.

## Caveats

- This is still single-run benchmarking.
- The prefetch strategy fetches all nodes and outgoing relationships; selective prefetch may be better for local traversals.
- Grid graphs are sparse and structured.
- The algorithms use simple frontier data structures, not optimized priority queues.

## Next Follow-Ups

- Add repeated benchmark runs with median/p95 output.
- Add denser random graph fixtures.
- Try connected components or cycle detection over snapshots.
