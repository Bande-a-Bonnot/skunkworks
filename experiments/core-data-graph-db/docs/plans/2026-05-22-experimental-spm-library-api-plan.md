# Experimental SPM Library API Plan

**Date:** 2026-05-22  
**Status:** parked / future direction  
**Experiment:** `experiments/core-data-graph-db/`

## Goal

Evolve the Core Data graph spike into an experimental Swift Package Manager library where users can model app-local graphs with Core Data, run graph algorithms efficiently, and optionally attach their own domain-specific node and edge types.

This is intentionally parked for now. The current benchmark spike should remain the evidence base; this plan captures the possible product/library shape for later.

## Current Evidence Base

The spike already demonstrates:

- Core Data can model first-class graph nodes and edges naturally.
- Directed weighted edges work cleanly as managed objects.
- BFS and Dijkstra work over both managed objects and value snapshots.
- SQLite-backed Core Data makes unmanaged fault-heavy traversal expensive.
- `relationshipKeyPathsForPrefetching` makes managed traversal much more viable.
- Snapshot adjacency traversal remains the cleanest/fastest path for algorithm hot loops.

Working hypothesis:

```text
Core Data is good as the persistent object graph / identity / relationship-integrity substrate.
Algorithm hot paths should usually run over value snapshots.
```

## Proposed Package Shape

Keep a library target plus separate benchmark/demo targets:

```text
CoreDataGraph
CoreDataGraphBenchmark
CoreDataGraphExamples
```

Possible public API surface:

```swift
GraphStore
Graph
GraphNode
GraphEdge
GraphSnapshot
GraphAlgorithms
GraphModelBuilder
```

A future package might be renamed from the experiment-local `CoreDataGraphDB` to something less database-claimy, such as:

- `CoreDataGraph`
- `ManagedGraph`
- `PersistentGraph`
- `ObjectGraphKit`

## Core Design Choice: Subclassing and/or Composition

### Option A: Simple Property Graph

Users create generic nodes/edges with type labels and property blobs:

```swift
let alice = graph.createNode(type: "person", properties: ["name": "Alice"])
let bob = graph.createNode(type: "person", properties: ["name": "Bob"])
graph.connect(alice, to: bob, kind: "follows", weight: 1.0)
```

Pros:

- Easy to start.
- No custom Core Data model required.
- Closest to property-graph databases.
- Good for tools, prototypes, importers, and dynamic schemas.

Cons:

- Less type-safe.
- Property blobs are harder to query/index.
- App code may become stringly typed.

### Option B: User Subclasses

Expose base managed-object classes as subclassable:

```swift
open class GraphNode: NSManagedObject { ... }
open class GraphEdge: NSManagedObject { ... }
```

Users define domain types:

```swift
final class PersonNode: GraphNode {
    @NSManaged var name: String
}

final class FollowsEdge: GraphEdge {
    @NSManaged var since: Date
}
```

Pros:

- Stronger domain modeling.
- Natural for app code.
- Queryable/indexable attributes.
- Plays to Core Data's strengths.

Cons:

- Core Data model registration becomes the hard part.
- Subclassing managed objects has sharp edges.
- Algorithms must not become coupled to user subclasses.

### Recommendation

Support both eventually:

1. **Simple property graph** for quick experiments and dynamic data.
2. **Advanced subclassed graph** for domain-rich apps.

Do not make subclassing the only extension model.

## Model Builder Requirement

Subclass support requires a programmatic model builder so users can register custom node and edge entities.

Sketch:

```swift
let model = GraphModelBuilder()
    .node(PersonNode.self, entityName: "PersonNode") {
        Attribute("name", .string, indexed: true)
    }
    .edge(FollowsEdge.self, entityName: "FollowsEdge") {
        Attribute("since", .date)
    }
    .build()
```

The builder would need to preserve required base relationships:

```text
GraphNode.outgoingEdges
GraphNode.incomingEdges
GraphEdge.source
GraphEdge.target
```

and layer user attributes/entities on top.

## Add a `Graph` Container Entity

Current spike assumes one graph per store. A library probably needs an explicit graph container:

```text
Graph
GraphNode
GraphEdge
```

This enables multiple graphs in one persistent store:

```swift
let social = try store.createGraph(name: "social")
let dependency = try store.createGraph(name: "dependencies")
```

Relationships:

```text
Graph.nodes
Graph.edges
GraphNode.graph
GraphEdge.graph
```

Open question: should cross-graph edges be forbidden by model constraints, runtime validation, or allowed deliberately?

## Algorithm Boundary

Algorithms should operate on neutral value snapshots, not on user subclasses.

```swift
let snapshot = try graph.snapshot(
    including: .edges(kind: "dependsOn")
)
let path = GraphAlgorithms.dijkstra(snapshot, from: a.id, to: b.id)
```

This keeps algorithms:

- fast;
- deterministic;
- independent of Core Data faulting;
- independent of user-defined managed-object subclasses;
- easier to test.

Managed-object traversal can still exist for small app-shaped interactions:

```swift
node.outgoing(kind: "contains")
node.neighbors()
```

But algorithm hot paths should prefer:

```text
Core Data graph -> value snapshot -> algorithm -> map IDs back to managed objects
```

## Edge Taxonomy

A reusable library should not assume all edges are just `source -> target`. Standard-ish edge categories include the following.

### Direction Shapes

- **Directed edge**: `A -> B`.
- **Undirected edge**: `A -- B`; can be modeled as one undirected edge or two directed edges.
- **Bidirectional edge**: `A <-> B`; often represented as paired directed edges.
- **Reverse/inverse edge**: materialized opposite relationship for traversal/query convenience.

### Multiplicity Shapes

- **Self-loop**: `A -> A`.
- **Multi-edge / parallel edge**: multiple distinct edges between the same nodes.
- **Hyperedge**: one edge connects more than two nodes; may require an edge-as-node or incidence model.

### Data-Bearing Edges

- **Weighted edge**: cost/distance/strength.
- **Labeled / typed edge**: `follows`, `dependsOn`, `contains`, `authoredBy`.
- **Attributed / property edge**: arbitrary metadata.
- **Temporal edge**: valid at a time or during a time range.
- **Versioned edge**: relation changes over history.
- **Signed edge**: positive/negative relation.
- **Probabilistic edge**: confidence/likelihood.

### Algorithm-Specific Edges

- **Capacity edge**: flow networks.
- **Cost edge**: shortest-path/planning algorithms.
- **Constraint edge**: ordering, dependency, exclusion, prerequisite.
- **Heuristic edge metadata**: useful for A* or domain-specific routing.

### Derived Edges

- **Computed edge**: derived from other data at query time.
- **Cached/materialized edge**: persisted for performance, but not primary truth.
- **Transitive edge**: precomputed reachability/closure relation.

## Potential API Sketch

```swift
let store = try GraphStore(model: model, store: .sqlite(url))
let graph = try store.createGraph(name: "social")

let alice = try graph.createNode(PersonNode.self) { node in
    node.name = "Alice"
}

let bob = try graph.createNode(PersonNode.self) { node in
    node.name = "Bob"
}

try graph.connect(alice, to: bob, as: FollowsEdge.self) { edge in
    edge.since = Date()
    edge.weight = 1
}

let snapshot = try graph.snapshot(edgeKinds: ["follows"])
let reachable = GraphAlgorithms.breadthFirst(snapshot, from: alice.id)
```

## Implementation Milestones

### M1 — Library API Cleanup

- Rename package/product if desired.
- Separate core library from benchmark/demo concerns.
- Make public API intentional and documented.
- Preserve current tests and benchmarks.

### M2 — Graph Container

- Add `Graph` entity.
- Scope nodes/edges to a graph.
- Add graph creation/fetch APIs.
- Add validation for same-graph connections.

### M3 — Property Graph Mode

- Add generic node/edge type labels.
- Add property storage strategy.
- Add basic property query/index story.

### M4 — Snapshot API

- Formalize snapshot creation.
- Support filters by graph, node type, edge kind, and direction.
- Keep algorithms over snapshots.

### M5 — Subclass Model Builder

- Introduce `GraphModelBuilder`.
- Register custom node/edge subclasses.
- Support custom attributes and indexes.
- Document Core Data subclassing constraints.

### M6 — Edge Shapes

- Directed edges first.
- Add undirected/bidirectional helpers.
- Evaluate hyperedges separately; likely not part of the first library slice.

### M7 — Algorithm Expansion

- Connected components.
- Cycle detection.
- Topological sort.
- A*.
- Maybe flow algorithms if capacity edges become interesting.

## Risks / Open Questions

- How much Core Data model-builder abstraction is worth it before it becomes a framework inside a framework?
- Can subclassed managed objects remain ergonomic without surprising users?
- Should property storage be JSON, binary plist, transformable, or separate property entities?
- Should graph algorithms return IDs only, lightweight node references, or lazy managed-object lookup helpers?
- How should migrations work for user-defined graph models?
- Is "graph database" the right framing, or is "Core Data graph toolkit" more honest?

## Parked Decision

Do not implement this now. Keep it as a future direction after the REST-layer experiment gets its own first spike.
