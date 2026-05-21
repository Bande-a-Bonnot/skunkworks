# Core Data Graph Database

> Experiment: implement a small graph database — nodes, edges, relationships, traversal, and algorithms including Dijkstra — using Core Data as the storage/object-graph substrate.

## Status

`idea`

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

No runnable code yet.

Suggested first implementation shape:

```bash
# from this directory, once created
swift package init --type executable
```

A pure Swift package with a programmatic Core Data model is probably enough for the first spike.

## Notes / Findings

- This is not trying to beat real graph databases.
- The interesting question is whether Core Data's relationship management gives enough leverage for app-local graph problems.
- Dijkstra may be cleaner over a snapshot adjacency list than live `NSManagedObject` faults; test both.

## Next Ideas

- [ ] Choose directed vs mixed graph representation.
- [ ] Create Swift package harness.
- [ ] Implement programmatic Core Data model.
- [ ] Seed sample graph fixtures.
- [ ] Implement BFS.
- [ ] Implement Dijkstra.
- [ ] Benchmark or at least instrument fault/fetch behavior.

## Cleanup / Graduation

Graduate if this becomes a reusable app-local graph toolkit. Archive if the conclusion is simply "Core Data is a decent backing store, but algorithms want snapshots" — that would still be useful.
