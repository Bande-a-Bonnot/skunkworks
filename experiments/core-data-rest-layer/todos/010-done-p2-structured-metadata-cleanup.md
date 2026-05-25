---
status: done
priority: p2
issue_id: "010"
tags: [core-data, metadata, pending-changes]
dependencies: ["009"]
---

# Structured Metadata Cleanup

## Goal

Replace the most important stringly typed pending-change states, pending-change field names, and task loaded-field metadata with small enums/helpers while preserving the existing model storage shape.

## Acceptance Criteria

- Add structured constants/enums for pending-change lifecycle states.
- Add structured constants/enums/helpers for pending-change field names and task loaded fields.
- Keep the stored Core Data attributes as strings for the spike.
- Update implementation and tests to use the structured API where practical.
- Run `swift test`.

## Result

Done on 2026-05-25. Added `PendingTaskChangeState`, `PendingTaskChangeField`, `TaskLoadedField`, and `MetadataListCodec`; updated store/projection/test call sites; kept public storage as strings.
