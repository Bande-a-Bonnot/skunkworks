# First Spike Benchmark Findings

**Date:** 2026-05-22  
**Experiment:** `core-data-graph-db`  
**Commands:**

```bash
swift test
swift run -c release CoreDataGraphDBBenchmark
```

## What Was Built

- Swift package with a programmatic Core Data model.
- `GraphNode` and first-class weighted directed `GraphEdge` entities.
- In-memory Core Data store.
- Deterministic graph fixtures.
- BFS and Dijkstra implementations over:
  - live `NSManagedObject` relationships;
  - a value-type adjacency snapshot.
- Benchmark executable comparing both traversal styles.

## Release Benchmark Snapshot

Environment: local macOS Swift 6.2.3, `NSInMemoryStoreType`, release build.

```text
case,nodes,edges,snapshot_ms,managed_bfs_ms,snapshot_bfs_ms,managed_dijkstra_ms,snapshot_dijkstra_ms,path_weight
small,100,180,0.167,0.118,0.021,0.209,0.115,59.000
medium,625,1200,0.657,0.638,0.116,1.779,1.220,168.000
large,2500,4900,2.860,2.540,0.502,10.878,8.403,343.000
```

## Initial Read

Core Data is perfectly comfortable as the graph identity/persistence substrate for this tiny local graph model. First-class edges and inverse relationships are natural.

For algorithmic hot paths, value snapshots are cleaner and faster:

- snapshot BFS is substantially faster than walking managed objects;
- snapshot Dijkstra is faster too, though the gap is smaller once both implementations avoid per-node fetches;
- snapshot build cost is visible but small for these graph sizes.

## Important Correction from the Spike

A first managed Dijkstra implementation fetched the current node by UUID on each frontier pop. That made the large benchmark dramatically worse. Rewriting it to keep `GraphNode` references in the frontier made the comparison fairer and more useful.

Lesson: when benchmarking Core Data graph traversal, distinguish relationship traversal from repeated fetch-query traversal.

## Current Working Hypothesis

Core Data should probably be treated as:

```text
persistent object graph + identity/change tracking + relationship integrity
```

and not as the best in-memory algorithm representation.

For non-trivial algorithms, fetch/snapshot into an adjacency list, run the algorithm, then map results back to Core Data node IDs/objects.

## Next Things to Learn

- Compare `NSInMemoryStoreType` with SQLite-backed stores.
- Add prefetching experiments for relationship-heavy managed traversal.
- Test larger sparse graphs and denser random graphs.
- Add indexes and measure fetch/snapshot costs.
