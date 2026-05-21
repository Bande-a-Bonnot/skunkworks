# Core Data REST Layer

> Experiment: use Core Data as an object graph / query / change-tracking layer on top of a Web REST API, rather than as a local-first SQLite/CloudKit persistence stack.

## Status

`idea`

## Why

Core Data is often treated as "the local database thing" or "an ORM for SQLite", but its more interesting identity is an object graph management framework: identity, relationships, faults, validation, change tracking, fetch requests, merge policies, undo, and contexts.

This experiment asks: what happens if the persistent backing is not local SQLite or CloudKit, but a REST API?

## Core Question

Can Core Data provide useful app-side ergonomics over remote resources without pretending the REST API is a local database?

## Hypotheses

- `NSManagedObjectContext` may be valuable as an identity map, unit-of-work, validation boundary, and object graph coordinator even when source-of-truth data is remote.
- A REST-backed Core Data layer could make SwiftUI/app code nicer: fetch predicates, sections, diffing, relationships, temporary IDs, optimistic edits.
- The hard parts will be impedance mismatches: pagination, partial objects, server filtering semantics, conflicts, latency, offline behavior, and relationship faulting.

## Candidate Approaches

### 1. Custom Persistent Store

Implement a custom Core Data persistent store / incremental store that translates fetches and saves to REST calls.

Pros:
- Most literal interpretation of "Core Data on top of REST".
- App code can remain close to normal Core Data usage.

Cons:
- Advanced Core Data surface area.
- REST APIs rarely match Core Data fetch semantics exactly.
- Faulting and relationship loading may become surprising.

### 2. Local Materialized Remote View

Use a normal local Core Data store as a materialized projection of remote API resources, with explicit sync/fetch adapters.

Pros:
- More practical and debuggable.
- Better offline story.
- Easier conflict handling and caching.

Cons:
- Less weird.
- Risks becoming "just another sync layer" instead of testing Core Data as the abstraction.

### 3. Hybrid Spike

Start with the local projection to learn the model, then attempt a minimal custom store for a tiny resource set.

## Minimal Domain

Start with a deliberately small REST-ish model:

- `Project`
  - `id`
  - `name`
  - `updatedAt`
- `Task`
  - `id`
  - `projectId`
  - `title`
  - `status`
  - `updatedAt`

Relationship:

- `Project.tasks`
- `Task.project`

## First Spike

Build a small Swift package or app that can:

1. Define a Core Data model for projects/tasks.
2. Read fixtures pretending to be REST responses.
3. Expose data through `NSManagedObjectContext` fetches.
4. Apply remote updates and local edits.
5. Document where Core Data helps vs where it fights the API boundary.

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

Then add a Core Data model programmatically or as a checked-in `.xcdatamodeld` if an app target becomes useful.

## Notes / Findings

- Core Data's precise phrase is "object graph and persistence framework". This experiment should lean on the object graph part and interrogate the persistence part.
- Avoid building a full generic REST ORM. Keep the first API tiny and concrete.
- Treat REST as remote truth with its own semantics, not as a lossy SQL endpoint.

## Next Ideas

- [ ] Decide first spike approach: custom store, materialized projection, or hybrid.
- [ ] Create minimal Swift package/app harness.
- [ ] Model project/task resources.
- [ ] Simulate latency, pagination, stale reads, and conflicts.
- [ ] Write down which Core Data features remain pleasant over REST.

## Cleanup / Graduation

Graduate if this yields a reusable pattern for app architecture. Archive if the custom-store route is mostly pain but capture the findings in `docs/solutions/`.
