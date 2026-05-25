# Pending-Change Semantics Spike Plan

Read-only planning result for `experiments/core-data-rest-layer`; no files edited.

## 1. Problem framing

The current custom-store path uses Core Data object changes plus `CDTask` metadata:

- `context.save()` on an edited `CDTask` sends `PATCH /tasks/{id}`.
- conflicts annotate the same `CDTask` with `isDirty`, `lastSyncError`, and `conflictState`.

That is enough for the first save/conflict spike, but dirty flags may be insufficient because they conflate three different states:

1. **Remote snapshot** — last accepted server truth.
2. **Local user intent** — the edit the user wants to apply.
3. **Write lifecycle** — pending, in-flight, failed, conflicted, applied.

As scenarios grow, flags on `CDTask` become ambiguous:

- `CDTask.title` may mean remote truth or unsaved local attempt.
- `isDirty` does not say which fields changed or what base version was used.
- conflict metadata is stringly typed and cannot preserve a full local attempt plus remote current state.
- retry/non-conflict failure semantics are not represented.
- multiple contexts or multiple pending edits can race or overwrite each other.
- partial-field loading makes field-level intent important: “not loaded” must not become “clear this field.”

## 2. Compare three designs

| Design | Shape | Pros | Cons | Verdict |
|---|---|---|---|---|
| Dirty flags on domain objects | Keep `isDirty`, `lastSyncError`, `conflictState` on `CDTask`; object values are the attempted local values. | Smallest change; existing tests already cover it; simple UI can inspect one object. | Mixes remote truth with local intent; weak field-level semantics; poor retry/offline story; conflict state grows on domain model; manual flag drift from Core Data change tracking. | Keep as baseline/legacy, but do not expand it much further. |
| Child/scratch context unit-of-work | Edit task in a private/scratch context; save attempts remote write; rollback cancels. | Uses Core Data’s intended unit-of-work, validation, undo, rollback, and changed-values machinery; avoids permanent dirty fields. | Ephemeral unless persisted elsewhere; conflicts are lost if context is discarded; not queryable as app state; parent/child save propagation can leak edits before remote acceptance if designed poorly. | Useful for edit forms, but not enough for durable pending writes. |
| Separate pending-change entities | Add local `CDPendingTaskChange` records containing task ID, base version, attempted values, state, error/conflict metadata. `CDTask` remains last known remote snapshot. | Makes local intent first-class and queryable; separates remote truth from pending writes; supports retry/conflict UI; aligns with existing explicit remote-state direction. | More model/store complexity; UI must overlay pending changes; local-only persistence needs a real strategy later; can become a sync engine if overbuilt. | Best next semantic pressure test if kept narrow and task-update-only. |

## 3. Recommendation: next smallest spike

Implement a **minimal separate pending-change entity** for task updates only:

- one pending update per task;
- only `title` / `status`;
- no creates/deletes;
- no generic payload system yet;
- no durable cross-process queue yet;
- keep existing direct `CDTask` save path and dirty flags so current tests remain a baseline.

Expected semantic decision for the spike:

```text
CDTask = last accepted remote snapshot
CDPendingTaskChange = local write intent + lifecycle
```

Child/scratch contexts can still be used later for edit UI, but on “Save” they should produce or update a pending-change record rather than directly mutating canonical `CDTask`.

## 4. Proposed model/code changes

### `Sources/CoreDataRESTLayer/CoreDataStack.swift`

Add:

```swift
@objc(CDPendingTaskChange)
public class CDPendingTaskChange: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var taskID: UUID
    @NSManaged public var baseVersion: Int64
    @NSManaged public var title: String
    @NSManaged public var status: String
    @NSManaged public var changedFields: String
    @NSManaged public var state: String // pending, failed, conflicted
    @NSManaged public var attemptCount: Int64
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var lastAttemptedAt: Date?
    @NSManaged public var lastError: String?
    @NSManaged public var conflictRemoteVersion: Int64
    @NSManaged public var conflictRemoteTitle: String?
    @NSManaged public var conflictRemoteStatus: String?
}
```

Add fetch helpers and uniqueness on `id`. Consider a logical one-change-per-task rule in helper code, not necessarily a Core Data uniqueness constraint for the spike.

### `Sources/CoreDataRESTLayer/RESTIncrementalStore.swift`

Add local-only support for `CDPendingTaskChange`:

- in-memory `pendingTaskChangeCache`;
- fetch support in `execute`;
- values support in `newValuesForObject`;
- permanent IDs in `obtainPermanentIDs`;
- save handling for inserted/updated/deleted pending changes without HTTP.

Add store-level apply helper, e.g.:

```swift
func applyPendingTaskChange(_ objectID: NSManagedObjectID) throws -> PendingTaskChangeApplyResult
```

Semantics:

- `pending` / `failed` changes can be applied.
- apply sends `PATCH /tasks/{taskID}` using pending `title`, `status`, and `baseVersion`.
- success updates `taskCache`, clears/removes pending change.
- conflict updates `taskCache` with remote current and marks pending as `conflicted` with remote snapshot.
- non-conflict HTTP failure marks pending as `failed` with `lastError`.

### `Sources/CoreDataRESTLayer/RESTIncrementalStore.swift` / `RESTCoreDataStack`

Add explicit app-facing APIs:

```swift
func stageTaskUpdate(for task: CDTask, title: String, status: String) throws -> CDPendingTaskChange

func flushPendingTaskChanges(in context: NSManagedObjectContext) throws -> [PendingTaskChangeOutcome]
```

Rules:

- staging does not mutate `CDTask`;
- staging does not call PATCH;
- repeated staging for the same task coalesces into one pending change while preserving original `baseVersion`;
- flush refreshes/faults affected `CDTask` from store cache rather than setting task fields in a way that triggers a second PATCH.

## 5. Proposed acceptance tests

Add tests in `Tests/CoreDataRESTLayerTests/CoreDataRESTLayerTests.swift`.

1. **Staging does not mutate remote snapshot or send PATCH**
   - fetch task through `RESTCoreDataStack`;
   - stage title/status update;
   - assert `CDTask.title` remains original;
   - assert server task remains original;
   - assert no `/tasks/{id}` PATCH request;
   - assert one `CDPendingTaskChange` exists with `baseVersion == 1`, attempted values, `state == "pending"`.

2. **Applying pending change patches server and clears pending**
   - stage update;
   - flush pending changes;
   - assert server task has attempted values and version increments;
   - assert `CDTask` refreshes to remote response;
   - assert pending change is deleted or marked applied;
   - assert `CDTask.isDirty == false`.

3. **Conflict preserves local attempt separately from remote current**
   - fetch task at version 1;
   - stage local update;
   - mutate server to version 2;
   - flush;
   - assert pending change is `conflicted`;
   - assert pending attempted title/status are preserved;
   - assert conflict remote version/title/status are recorded;
   - assert `CDTask` represents remote current, not the local attempt.

4. **HTTP failure leaves retryable pending change**
   - force PATCH 500;
   - flush;
   - assert pending state is `failed`, `lastError` contains response body, attempt count increments;
   - clear forced response;
   - flush again succeeds using same pending change.

5. **Repeated staging coalesces**
   - stage update A;
   - stage update B for same task before flush;
   - assert one pending change exists;
   - assert `baseVersion` remains the original task version;
   - assert attempted values are from update B.

## 6. Risks and non-goals

Risks:

- local-only pending entities inside the current `NSIncrementalStore` cache are not durable across process restart;
- refreshing `CDTask` after apply/conflict must avoid triggering a second `PATCH`;
- direct edits to `CDTask` remain possible, so APIs must document the preferred path;
- UI will need an overlay pattern to display pending values over remote snapshots.

Non-goals for this spike:

- generic pending-change framework;
- inserts/deletes;
- relationship mutations;
- offline durability;
- cancellation/background scheduling;
- replacing all existing dirty-flag tests;
- full conflict-resolution UI.

## 7. Draft todo file

```markdown
---
status: ready
priority: p2
issue_id: "009"
tags: [core-data, custom-store, pending-changes, conflicts]
dependencies: ["008"]
---

# Spike Pending-Change Semantics

Design and implement the next narrow custom-store spike for local edit semantics. Compare current dirty flags with a first-class pending-change record for task updates.

## Goal

Test whether `CDTask` should remain the last accepted remote snapshot while local user intent lives in a separate `CDPendingTaskChange` entity.

## Acceptance Criteria

- Add a minimal `CDPendingTaskChange` managed entity for update-only task edits.
- Staging a task update does not mutate `CDTask` and does not send `PATCH`.
- Applying a pending change sends `PATCH /tasks/{id}` with the pending values and base version.
- Successful apply updates the task cache/object to the remote response and clears the pending change.
- Conflict preserves the local attempted values on the pending change and records the remote current task separately.
- Non-conflict HTTP failure leaves a retryable pending change with error metadata.
- Repeated staging for the same task coalesces into one pending change.
- Document whether pending entities are a better semantic fit than dirty flags or child-context-only units of work.

## Non-Goals

- Generic REST sync engine.
- Inserts/deletes.
- Durable offline queue.
- Conflict-resolution UI.
- Removing existing dirty-flag baseline behavior.
```
