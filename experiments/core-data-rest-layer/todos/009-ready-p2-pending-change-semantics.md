---
status: ready
priority: p2
issue_id: "009"
tags: [core-data, custom-store, pending-changes, conflicts]
dependencies: ["008"]
---

# Spike Pending-Change Semantics

Design and implement the next narrow custom-store spike for local edit semantics. Compare current dirty flags with a first-class pending-change record for task updates.

Plan: `docs/plans/2026-05-25-pending-change-semantics-plan.md`.

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
