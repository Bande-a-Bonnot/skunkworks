# Core Data Graph Database First Spike Plan

**Date:** 2026-05-22  
**Status:** completed 2026-05-22  
**Experiment:** `experiments/core-data-graph-db/`

## Goal

Create the smallest runnable Swift/Core Data graph database spike that can answer an initial version of the experiment's core question:

> Is Core Data useful as the graph engine itself, or mainly as the persistence/object-identity substrate beneath a graph engine?

## Initial Slice

Build a local Swift package inside this experiment directory with:

- programmatic Core Data model;
- in-memory persistent store;
- first-class node and edge entities;
- directed weighted edges;
- deterministic seeded graphs;
- BFS;
- Dijkstra shortest path;
- benchmarks comparing direct managed-object traversal with value-snapshot traversal.

## Minimal Model

### `GraphNode`

- `id: UUID`
- `label: String?`
- `outgoingEdges: Set<GraphEdge>`
- `incomingEdges: Set<GraphEdge>`

### `GraphEdge`

- `id: UUID`
- `kind: String?`
- `weight: Double`
- `source: GraphNode`
- `target: GraphNode`

Edges are first-class entities so they can carry weights, kinds, and future properties.

## Algorithm Acceptance Tests

### BFS

Given a deterministic sample graph:

```text
A -> B
A -> C
B -> D
C -> D
D -> E
```

BFS from `A` returns:

```text
A, B, C, D, E
```

Traversal order is deterministic by sorting outgoing edges by target label/ID.

### Dijkstra

Given a weighted graph:

```text
A -> B (4)
A -> C (1)
C -> B (2)
B -> D (1)
C -> D (5)
```

Shortest path from `A` to `D` returns:

```text
A -> C -> B -> D, total weight 4
```

## Traversal Comparison

Implement both:

1. **Managed-object traversal** — algorithms walk `GraphNode.outgoingEdges` directly.
2. **Snapshot traversal** — fetch nodes/edges once into value types and walk an adjacency list.

Compare:

- API ergonomics;
- deterministic behavior;
- runtime for BFS and Dijkstra;
- snapshot build cost;
- whether algorithm code is polluted by Core Data concerns.

## Benchmark Acceptance

Add a benchmark executable that prints timings for multiple graph sizes.

Minimum benchmark cases:

- small grid;
- medium grid;
- larger grid if runtime remains reasonable.

For each case, print:

- node count;
- edge count;
- snapshot build time;
- managed BFS time;
- snapshot BFS time;
- managed Dijkstra time;
- snapshot Dijkstra time.

## Verification Commands

From `experiments/core-data-graph-db/`:

```bash
swift test
swift run CoreDataGraphDBBenchmark
```

## Completion Notes

Implemented as planned. The first benchmark result suggests Core Data is pleasant for identity/persistence and small graph traversal, while snapshot adjacency traversal is noticeably better for algorithmic hot paths once graph size grows.
