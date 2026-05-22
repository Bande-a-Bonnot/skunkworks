# Core Data REST Layer First Spike Plan

**Date:** 2026-05-22  
**Status:** ready for implementation  
**Experiment:** `experiments/core-data-rest-layer/`

## Goal

Build the first runnable spike for using Core Data as an object graph, identity, validation, and change-tracking layer over a REST API.

The spike should use a real local HTTP boundary, not static fixtures:

```text
embedded local REST server -> URLSession client -> Core Data projection -> app-style fetch/edit/sync
```

## Why an Embedded Server

Static fixtures are useful, but they skip the most interesting mismatch between Core Data and REST: HTTP behavior.

An embedded server gives us real, deterministic REST semantics without external infrastructure:

- status codes;
- JSON encoding/decoding;
- latency and cancellation hooks;
- optimistic concurrency with ETags or versions;
- server-side mutation between syncs;
- deleted remote resources;
- pagination later;
- conflict responses such as `409` or `412`.

The server should bind to `127.0.0.1:0` during tests and expose its assigned base URL to the client.

## First-Slice Architecture

```text
Tests / demo executable
        |
        v
EmbeddedRESTServer  <---- in-memory remote state
        |
        v
URLSession RESTClient
        |
        v
ProjectionSync
        |
        v
Core Data store / NSManagedObjectContext
        |
        v
App-style fetches and local edits
```

## Package Shape

Create a Swift package inside `experiments/core-data-rest-layer/`.

Suggested targets:

```text
CoreDataRESTLayer
CoreDataRESTLayerTestServer
CoreDataRESTLayerTests
```

`CoreDataRESTLayerTestServer` can be test/support code rather than a public library product.

## Server Implementation Options

### Option A — Small Swift Server Dependency

Use a small server stack such as Hummingbird/SwiftNIO.

Pros:

- Real HTTP server quickly.
- Less time spent hand-rolling protocol parsing.
- Easier async tests.

Cons:

- Adds package dependencies to the experiment.
- More moving pieces than a fixture loader.

### Option B — Tiny `Network.framework` Server

Implement a minimal local HTTP server directly.

Pros:

- No package dependencies.
- Full control.

Cons:

- More annoying and less relevant to the Core Data question.
- Easy to accidentally spend the spike on HTTP plumbing.

### Recommendation

Use a small dependency if it keeps the server boring. The experiment is about Core Data over REST, not HTTP parser implementation.

## Minimal Remote Domain

### Project

```json
{
  "id": "uuid",
  "name": "Skunkworks",
  "updatedAt": "2026-05-22T00:00:00Z",
  "version": 1
}
```

### Task

```json
{
  "id": "uuid",
  "projectId": "uuid",
  "title": "Wire embedded server",
  "status": "open",
  "updatedAt": "2026-05-22T00:00:00Z",
  "version": 1
}
```

Relationship:

```text
Project.tasks <-> Task.project
```

## Initial Endpoints

Minimum useful endpoints:

```http
GET /projects
GET /projects/{projectID}/tasks
PATCH /tasks/{taskID}
```

Optional test controls:

```http
POST /__test__/reset
POST /__test__/mutate/task
POST /__test__/set-latency
```

The first conflict mechanism can use either:

- `ETag` + `If-Match`; or
- explicit `version` fields in JSON.

Recommendation: use explicit integer `version` first, because it is easy to inspect in Core Data and tests. ETags can be added later.

## Core Data Model

### `CDProject`

- `id: UUID`
- `name: String`
- `updatedAt: Date`
- `version: Int64`
- `tasks: Set<CDTask>`

### `CDTask`

- `id: UUID`
- `project: CDProject`
- `title: String`
- `status: String`
- `updatedAt: Date`
- `version: Int64`
- local sync metadata:
  - `isDirty: Bool`
  - `lastSyncError: String?`
  - `conflictState: String?`

## First Scenario Acceptance Test

1. Start embedded server with one project and two tasks.
2. Sync projects and tasks through `URLSession` into Core Data.
3. Fetch project/tasks from Core Data using normal fetch requests and relationships.
4. Locally edit a task title/status in Core Data and mark it dirty.
5. Push the local edit via `PATCH /tasks/{taskID}` with the known version.
6. Server accepts the patch, increments version, returns updated task.
7. Core Data clears `isDirty`, updates version, and keeps relationship integrity.

## Conflict Scenario Acceptance Test

1. Sync a task at version `1`.
2. Server mutates the same task to version `2` through a test-control endpoint or direct server-state API.
3. Local Core Data edits attempt to patch with stale version `1`.
4. Server returns a conflict (`409` or `412`) with the current remote task.
5. Core Data records conflict state instead of silently overwriting.
6. The test can inspect both local attempted values and remote current values, or at least verify `conflictState` / `lastSyncError` is set.

## What This Spike Should Learn

- Whether Core Data relationships/fetches make app-side access nicer after remote sync.
- Whether Core Data change tracking is useful for outbound REST patches.
- Where remote loading/error/conflict state should live.
- How much REST semantics should leak into managed-object fields.
- Whether a custom persistent store still seems interesting after a practical projection layer exists.

## Non-Goals

- Generic REST ORM.
- Full offline sync engine.
- CloudKit-like bidirectional sync.
- Pagination beyond a documented placeholder.
- Background sync scheduling.
- Custom Core Data persistent store.

## Verification Commands

Expected once implemented:

```bash
cd experiments/core-data-rest-layer
swift test
```

If a demo executable is added:

```bash
swift run CoreDataRESTLayerDemo
```

## Implementation Milestones

### M1 — Package and Model

- Create Swift package.
- Add programmatic Core Data model or checked-in model file.
- Add managed object classes.

### M2 — Embedded Server

- Add local test server target.
- Bind to `127.0.0.1:0`.
- Implement in-memory remote state and baseline endpoints.

### M3 — REST Client

- Implement URLSession client for projects/tasks.
- Decode/encode JSON.
- Surface status codes explicitly.

### M4 — Projection Sync

- Pull remote project/task data into Core Data.
- Preserve identities and relationships.
- Track remote versions.

### M5 — Local Edit + Push

- Edit managed task locally.
- Mark dirty.
- PATCH to server.
- Clear dirty state on success.

### M6 — Conflict

- Simulate server-side mutation.
- Attempt stale local patch.
- Record conflict state in Core Data.

## Parked Questions

- Should version/ETag be modeled as domain data, sync metadata, or both?
- Should conflict state be a string, enum field, or separate entity?
- Should local edits use child contexts as units of work?
- Can fetch predicates be mapped back to REST queries later, or should Core Data remain a projection only?
- Is a custom persistent store still worth exploring after this slice?
