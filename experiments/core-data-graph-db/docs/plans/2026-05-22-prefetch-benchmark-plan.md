# Relationship Prefetch Benchmark Plan

**Date:** 2026-05-22  
**Status:** completed 2026-05-22  
**Experiment:** `experiments/core-data-graph-db/`

## Goal

Measure whether Core Data relationship prefetching improves managed-object graph traversal, especially SQLite-backed BFS after a context reset.

## Scope

- Add a prefetch phase to the benchmark using `relationshipKeyPathsForPrefetching`.
- Prefetch `outgoingEdges` and `outgoingEdges.target` for all nodes.
- Measure prefetch cost separately.
- Compare:
  - managed BFS without prefetch;
  - managed BFS after prefetch;
  - snapshot BFS;
  - managed Dijkstra without prefetch;
  - managed Dijkstra after prefetch;
  - snapshot Dijkstra.
- Avoid cross-contaminating measurements by resetting the context before each strategy.

## Acceptance Criteria

- `swift test` passes.
- `swift run -c release CoreDataGraphDBBenchmark --store both` runs successfully.
- Output includes prefetch cost and prefetched traversal columns.
- Findings are documented in `docs/solutions/`.
- Todo `005` is marked done.
