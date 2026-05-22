# Core Data Graph Database

> Experiment: implement a small graph database — nodes, edges, relationships, traversal, and algorithms including Dijkstra — using Core Data as the storage/object-graph substrate.

## Status

`spike`

## Why

Core Data already manages object graphs and relationships. Graph databases manage nodes, edges, traversals, and relationship-heavy queries. This experiment asks how far Core Data can be pushed toward an explicit graph database model before it becomes silly, surprisingly good, or both.

## Core Question

Can Core Data serve as a practical substrate for graph storage and graph algorithms, not just app entities with relationships?

## Scope

Implement a small graph engine with:

- nodes;
- directed and/or undirected edges;
- edge weights;
- labels/types;
- basic traversal;
- shortest path with Dijkstra;
- possibly reachability, connected components, and cycle detection.

## Candidate Model

### Node

- `id: UUID`
- `label: String?`
- `properties: Data` or JSON-ish blob
- outgoing edges relationship
- incoming edges relationship

### Edge

- `id: UUID`
- `source: Node`
- `target: Node`
- `kind: String?`
- `weight: Double`
- `properties: Data` or JSON-ish blob

## Algorithms to Try

- Breadth-first search
- Depth-first search
- Reachability
- Neighbors by edge kind
- Connected components
- Cycle detection
- Topological sort for DAGs
- Dijkstra shortest path
- Maybe A* if coordinates/heuristics are added

## Core Data Things to Probe

- Relationship traversal performance
- Faulting behavior during graph walks
- Fetch batching and prefetching
- Indexes for node IDs and edge endpoints
- Modeling edge properties cleanly
- In-memory vs SQLite-backed stores
- Background contexts for long-running algorithms
- Whether algorithm code should operate on managed objects or copied value snapshots

## First Spike

Build a tiny Swift command-line package or test target that:

1. Creates a Core Data model for `GraphNode` and `GraphEdge`.
2. Seeds a small weighted graph.
3. Implements BFS and Dijkstra.
4. Compares managed-object traversal against a value-snapshot adjacency list.
5. Records where Core Data helps and where it gets in the way.

## Local Project Files

- `AGENTS.md` — local agent instructions.
- `docs/HANDOFF.md` — current state and exact next action.
- `docs/initial-questions.md` — question bank.
- `todos/` — local task breakdown.

## Quick Start

From this directory:

```bash
swift test
swift run -c release CoreDataGraphDBBenchmark --store both
swift run -c release CoreDataGraphDBBenchmark --store both --format csv
```

The package uses a programmatic Core Data model and an in-memory store for the first spike.

## Notes / Findings

- This is not trying to beat real graph databases.
- The interesting question is whether Core Data's relationship management gives enough leverage for app-local graph problems.
- First spike implemented BFS and Dijkstra over both live managed-object relationships and a value snapshot.
- Early benchmark read: Core Data is comfortable for identity/persistence/relationship integrity; snapshots are cleaner and faster for algorithmic hot paths.
- Detailed first-spike findings: `docs/solutions/2026-05-21-first-spike-benchmark-findings.md`.
- SQLite vs in-memory findings: `docs/solutions/2026-05-22-sqlite-vs-in-memory-benchmark-findings.md`.
- Relationship prefetch findings: `docs/solutions/2026-05-22-relationship-prefetch-benchmark-findings.md`.
- Parked SPM library API direction: `docs/plans/2026-05-22-experimental-spm-library-api-plan.md`.

## Next Ideas

- [x] Choose directed vs mixed graph representation.
- [x] Create Swift package harness.
- [x] Implement programmatic Core Data model.
- [x] Seed sample graph fixtures.
- [x] Implement BFS.
- [x] Implement Dijkstra.
- [x] Benchmark or at least instrument fault/fetch behavior.
- [x] Compare in-memory and SQLite-backed stores.
- [x] Add relationship prefetch experiments.
- [ ] Add repeated benchmark runs with median/p95 output.
- [ ] Add denser random graph fixtures.

## Cleanup / Graduation

Graduate if this becomes a reusable app-local graph toolkit. Archive if the conclusion is simply "Core Data is a decent backing store, but algorithms want snapshots" — that would still be useful.
