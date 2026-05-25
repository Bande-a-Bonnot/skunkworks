# Structured Metadata Cleanup Findings

**Date:** 2026-05-25

## Summary

The pending-change and loaded-field metadata can be made less stringly typed without changing the spike's public Core Data storage model.

## Implemented Shape

- Added `PendingTaskChangeState` for `pending`, `failed`, and `conflicted`, with a `canFlush` helper.
- Added `PendingTaskChangeField` for changed pending-task fields.
- Added `TaskLoadedField` for explicit task completeness metadata.
- Added `MetadataListCodec` to encode/decode comma-separated metadata in one place.
- Added `CDPendingTaskChange.stateValue`, `CDPendingTaskChange.changedFieldSet`, and `CDTask.loadedFieldSet` helpers.

## Decision

Keep `CDTask.loadedFields`, `CDPendingTaskChange.changedFields`, and `CDPendingTaskChange.state` as string attributes for this spike. The typed API now wraps those strings at usage boundaries, which is enough to remove the most fragile literals without overbuilding a migration or durable sync schema.

## Verification

```bash
cd experiments/core-data-rest-layer
swift test
```

Passed on 2026-05-25: 25 XCTest tests.
