# Core Data over REST Synthesis

**Date:** 2026-05-24

## Summary

Core Data can be useful over REST, but not as an illusion that a remote API is a local database. The most promising value is app-side object graph ergonomics: identity, relationships, contexts, validation boundaries, save units, and UI-friendly fetch APIs. The least promising value is transparent persistence: hiding network, pagination, partial responses, conflicts, and loading state behind ordinary property access quickly becomes surprising.

The viable shape is therefore not “REST disappears behind Core Data.” It is:

```text
Core Data object graph + explicit remote state + explicit load/save operations
```

## What Stayed Pleasant

### Identity and Object Graphs

Core Data's identity map remains useful. `NSManagedObjectID`s provide stable references for remote resources, and relationships like `Project.tasks` / `Task.project` are pleasant once loaded.

This is especially nice for app/UI code that wants to pass object IDs between contexts, render object graphs, or keep one in-memory object per remote resource identity.

### Fetch Requests as App Queries

Simple fetch requests are ergonomic when they map to coarse REST collection endpoints such as `GET /projects` or `GET /projects/{id}/tasks`.

The win is not arbitrary SQL-over-HTTP. The win is letting app code express common screen-level loads through familiar Core Data fetch APIs while the store owns object materialization.

### Contexts as Unit-of-Work Boundaries

`NSManagedObjectContext` is still valuable as a place to stage edits, validate object changes, and decide when to attempt a remote write.

A task edit followed by `context.save()` mapping to `PATCH /tasks/{id}` is plausible for small resources. Save conflicts can annotate the attempted object and throw a typed error, preserving local user intent for conflict UI.

### Relationship Modeling

Relationships remain one of Core Data's strongest features. Once object IDs and inverse relationships are wired correctly, app code can navigate the graph naturally.

The caveat is that relationship completeness must be explicit when REST pagination is involved. `CDRemoteRelationshipState` makes this inspectable from Core Data instead of hiding it in ad hoc caller state.

### Background Context Execution

Private-queue contexts give a workable execution policy for blocking store operations. They do not solve the synchronous nature of `NSIncrementalStore`, but they provide a clear rule: app-facing loads and saves should run off the main context.

## What Fought the REST Boundary

### Synchronous Store Hooks

`NSIncrementalStore` calls are synchronous, while REST is latency-bound, failure-prone, and ideally cancellable. A blocking HTTP bridge is acceptable for a spike, but it means every fetch, fault, and save can become network I/O.

This makes direct UI property access dangerous unless objects and relationships have been explicitly preloaded.

### Relationship Faulting and Pagination

Relationship faulting can call REST endpoints, but paginated REST collections leak through the abstraction:

- cursor APIs need continuation state;
- offset APIs can race concurrent inserts/deletes;
- numbered pages need total-count semantics;
- all strategies need completeness/error metadata.

A Core Data relationship alone cannot honestly represent remote collection truth. It needs a companion remote-state model.

### Partial Scalar Fields

Sparse list responses create ambiguity for optional fields. If `Task.notes == nil`, app code must know whether the server returned JSON `null` or whether the field has not been loaded yet.

The spike's answer is explicit `loadedFields` metadata plus an explicit detail load. Hiding scalar detail loads behind ordinary property access would be too surprising.

### Error Boundaries

Thrown errors from `context.fetch` and `context.save` are manageable. Errors from relationship faulting are awkward because plain property access is not a nice Swift `throws` boundary.

Typed store errors help, but app code still needs explicit load APIs around relationship/detail prefetching to provide good UI recovery.

### Query Translation

Core Data fetch requests are broad; REST endpoints are narrow and contract-specific. A generic predicate/sort translation layer would quickly become a REST ORM and probably fail on real APIs.

This experiment should keep rejecting arbitrary SQL-over-HTTP. Only intentionally supported fetch shapes should map to endpoints.

## Recommended Architecture If Continued

Use Core Data as the local object graph and unit-of-work API, but make remote semantics first-class:

1. Supported fetch/load operations are explicit and endpoint-shaped.
2. Relationship and field completeness live in managed remote-state records or generated metadata.
3. UI code reads already-loaded objects; background contexts perform remote loads/saves.
4. Save conflicts preserve local attempted edits and expose remote state for explicit resolution.
5. Pagination, partial fields, API versions, local model versions, and resource versions are modeled separately.

## Practical Pattern

A production-ish API might look more like:

```swift
try await loader.loadProjects()
try await loader.loadTasks(for: projectID, policy: .allPages)
try await loader.loadTaskDetails(taskID)
try await writer.saveTaskEdits(taskID)
```

Underneath, those operations may use Core Data contexts and a custom store, but app code should not rely on random property access to start network work.

## Current Verdict

The custom store path is worthwhile as a conceptual spike. It proves Core Data can front a REST API for a tiny domain, and it makes the impedance mismatches concrete.

The main lesson is that the valuable abstraction is not transparent persistence; it is a disciplined object graph with explicit remote truth metadata. If this becomes reusable, its API should advertise remote loading states rather than hiding them.

## Next Useful Work

- Design pending-change entities or child-context flows for local edits instead of simple dirty flags.
- Add cancellation/timeout policy around app-level load operations.
- Replace comma-delimited field completeness with structured generated metadata.
- Decide whether to graduate this into a small library prototype or archive it as findings.
