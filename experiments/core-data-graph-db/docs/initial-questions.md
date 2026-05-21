# Initial Questions — Core Data Graph Database

## Conceptual

- Is Core Data better treated as the graph database itself, or as a persistence layer for a graph engine?
- Should algorithms traverse live `NSManagedObject` relationships or a value-type adjacency snapshot?
- How should graph-level transactions map to Core Data contexts and saves?
- Which graph database ideas are useful locally inside an app, and which are unnecessary ceremony?

## Model Questions

- Should edges be first-class entities? Probably yes, because they need weights and properties.
- Should the graph support directed, undirected, or mixed edges?
- Should labels/kinds be strings, enums, separate entities, or indexed attributes?
- How should arbitrary node/edge properties be represented: JSON blob, transformable, child entities, or typed schemas?

## Algorithm Questions

- How much faulting happens during traversal?
- Does prefetching outgoing edges materially improve traversal?
- Is Dijkstra acceptable over managed objects for small graphs?
- When does it become better to fetch once into an adjacency list?
- Can algorithms run safely in background contexts without surprising object identity issues?

## Core Data Features to Test

- To-many relationship traversal
- Inverse relationships
- Delete rules for node/edge cleanup
- Fetch indexes on node IDs, edge source, edge target, and kind
- In-memory store for tests
- SQLite store for persistence/performance comparison
- Batch fetching / prefetch relationship key paths

## Success Signals

- Simple graph operations are pleasant to express.
- Core Data handles identity and persistence cleanly.
- Algorithms can be implemented without fighting faults/context boundaries too much.
- The implementation suggests a useful app-local graph pattern.

## Failure Signals

- Algorithm code is full of Core Data lifecycle defensive work.
- Faulting dominates traversal behavior.
- Relationship queries are harder than maintaining an explicit adjacency structure.
- The result is just a slower, more complicated dictionary-of-arrays.
