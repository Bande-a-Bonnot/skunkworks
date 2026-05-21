# Core Data Graph Database Handoff

**URN:** `skunkworks::local::experiment::core-data-graph-db::handoff::019e4c87-dd7e-75ef-a7e6-feb136eb2d9c`  
**Last updated:** 2026-05-21  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on `experiments/core-data-graph-db/`.

---

## Purpose

Explore whether Core Data can serve as a useful app-local graph database substrate: nodes, first-class weighted edges, relationship traversal, and algorithms such as BFS and Dijkstra.

## Current State

Documentation-only seed exists:

- `README.md` describes the experiment, model, algorithms, and first spike.
- `docs/initial-questions.md` captures model/algorithm/Core Data questions.
- Local agent/process scaffold now exists:
  - `AGENTS.md`
  - `docs/HANDOFF.md`
  - `docs/README.md`
  - `docs/{brainstorms,plans,solutions,runbooks}/`
  - `todos/README.md`

No runnable Swift harness exists yet.

## Working Direction

The first spike should be deliberately small:

```text
Swift package -> programmatic Core Data model -> in-memory store -> seed graph -> BFS + Dijkstra -> findings
```

Compare direct managed-object traversal with a value-type adjacency-list snapshot. The key learning is whether Core Data should be the graph engine or the persistence substrate beneath one.

## Local Todos

- `001` — `todos/001-ready-p1-write-first-spike-plan.md`
- `002` — `todos/002-pending-p1-build-core-data-graph-harness.md`
- `003` — `todos/003-pending-p1-implement-bfs-and-dijkstra.md`

## Open Questions

- Should algorithms traverse managed objects directly or snapshots?
- How much does faulting affect traversal?
- What indexes/prefetching are needed for graph-shaped access?
- Is this useful for app-local graph problems even if it is not a general graph database?

## Verification

Current verification is file/catalog consistency only. Once code exists, add the smallest useful command here and in `README.md`.

## Next Action

Write `docs/plans/2026-05-21-core-data-graph-db-first-spike-plan.md`, then create the Swift package harness.
