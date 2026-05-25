## 1. Executive verdict

`experiments/core-data-graph-db` successfully delivers its **first-spike brief**: a small Core Data-backed directed weighted graph model with first-class edges, BFS, Dijkstra, value snapshots, SQLite/in-memory comparisons, prefetch benchmarking, documentation, and passing tests.

It is **not** a general graph database/toolkit yet. The implementation is best read as evidence for the documented hypothesis:

> Core Data is useful for persistence, identity, and relationship integrity; graph algorithm hot paths are cleaner/faster over value snapshots.

Recommendation: **park, not graduate/archive**.

---

## 2. Original brief/goals as understood

The experiment asked whether Core Data can act as a practical substrate for app-local graph storage and algorithms by building a small Swift/Core Data graph spike with:

- `GraphNode` / `GraphEdge` model.
- First-class directed weighted edges.
- Labels/kinds.
- BFS and Dijkstra.
- Managed-object traversal vs value-snapshot adjacency traversal.
- Benchmarking/instrumentation around Core Data faulting, SQLite vs in-memory stores, and relationship prefetching.
- Findings documented clearly enough to decide whether to continue, productize, or abandon.

---

## 3. Goal coverage matrix

| Goal | Evidence | Status |
|---|---|---|
| Swift package harness | `Package.swift` with library, benchmark executable, tests | Complete |
| Programmatic Core Data model | `CoreDataGraphModel.makeModel()` | Complete |
| Nodes and first-class edges | `GraphNode`, `GraphEdge`, source/target/incoming/outgoing relationships | Complete |
| Directed weighted edges | `createEdge(... weight:kind:)`, grid/Dijkstra fixtures | Complete |
| Labels/types | Node `label`, edge `kind` | Mostly complete |
| Arbitrary properties | Candidate brief mentioned JSON/blob properties | Not implemented |
| BFS | `breadthFirstManaged`, `breadthFirstSnapshot` | Complete |
| Dijkstra | `dijkstraManaged`, `dijkstraSnapshot` | Complete |
| Managed vs snapshot traversal | Both implementations plus benchmark columns | Complete |
| SQLite vs in-memory | `GraphStore(storeType:storeURL:)`, benchmark `--store` | Complete |
| Faulting/context reset behavior | Benchmark resets context between strategies | Complete |
| Relationship prefetching | Benchmark prefetches `outgoingEdges`, `outgoingEdges.target` | Complete |
| Repeated benchmark statistics | Todo `006` pending | Not yet |
| Random/dense graph fixtures | Todo `007` pending | Not yet |
| More graph algorithms | Reachability/components/cycle/toposort were optional | Not covered |
| Background contexts | Initial question only | Not covered |
| Indexes/constraints | Initial questions mention IDs/endpoints/kind indexes | Not implemented |
| Reusable SPM library API | Parked plan exists | Deferred |

---

## 4. Implementation strengths

- Clean minimal Core Data model with proper first-class edge entities.
- Clear split between storage/model code, algorithms, benchmarks, and tests.
- Snapshot representation is simple and supports the main experiment conclusion.
- Benchmark design improved over time: SQLite support, context resets, prefetch measurement, CSV/table output.
- Documentation is unusually good for a spike: plans, findings, handoff, todos all align.
- Tests pass:

```text
swift test
Executed 6 tests, 0 failures
```

Repo status was clean after review.

---

## 5. Gaps / risks / mismatches

- **Not a full graph database**: no query language, indexing strategy, graph container, transactions API, property graph model, migrations, or multi-graph support.
- **No indexes or uniqueness constraints** on node IDs, labels, edge endpoints, or kind. This matters for SQLite-backed scaling.
- **Dijkstra accepts negative weights** without validation/documentation; Dijkstra is invalid for negative edge weights.
- **Dijkstra tie-breaking is not deterministic** for equal-distance frontier nodes because it uses `Set`/dictionary key ordering with distance-only comparison.
- **Edge kind is stored but not algorithmically useful yet**: no neighbor filtering or traversal by kind.
- **No arbitrary node/edge properties**, despite being part of the candidate model questions.
- **Benchmark rigor is limited**: single-run measurements over sparse right/down grids only.
- **No background context/concurrency exploration**, despite being an initial Core Data question.
- **Benchmark prefetch accounting is slightly uneven**: endpoint fetches are included in the prefetch timing but not in the plain managed/snapshot timings.

---

## 6. Test / verification assessment

Current tests cover the core spike well:

- Node/edge creation and inverse relationships.
- BFS deterministic fixture order.
- Dijkstra shortest path.
- Unreachable Dijkstra target.
- Grid fixture counts.
- SQLite persistence/refetch.

Missing useful tests:

- Negative weight rejection or documented behavior.
- Equal-cost Dijkstra tie behavior.
- Duplicate labels / nil labels.
- Edge kind filtering once supported.
- Delete cascade behavior.
- Snapshot determinism with parallel edges.
- CLI argument behavior.
- Prefetch correctness/benchmark smoke test.

---

## 7. Recommended next actions

1. **Keep parked unless productizing.**
2. If continuing benchmarks:
   - implement `--runs` with median/p95;
   - add deterministic sparse/dense random fixtures.
3. If moving toward a reusable library:
   - add ID uniqueness/indexes;
   - validate non-negative Dijkstra weights;
   - make Dijkstra tie-breaking deterministic;
   - add edge-kind traversal/filtering;
   - decide property graph vs subclass model.
4. Add tests for deletion rules, negative weights, duplicate labels, and equal-cost paths.
5. Document clearly that current algorithms assume directed, non-negative weighted graphs.

---

## 8. Continue, park, graduate, or archive?

**Park.**

The spike met its evidence-gathering goals and produced useful findings. It should not graduate yet because the API and data model are not robust enough for reuse. It should not be archived because the documented benchmark evidence and parked SPM-library plan remain valuable.
