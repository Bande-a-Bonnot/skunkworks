---
status: ready
priority: p2
issue_id: "008"
tags: [core-data, custom-store, partial-loading]
dependencies: ["007"]
---

# Explore Partial Object Field Loading

Extend the custom REST store beyond relationship completeness into partial object/field completeness.

## Acceptance Criteria

- Add a small detail-only field to `Task` or a parallel metadata entity for loaded field sets.
- Simulate a list endpoint returning partial task data and a detail endpoint returning full task data.
- Decide how Core Data object faults or explicit refreshes should load details.
- Tests show app code can distinguish null/empty values from not-yet-loaded fields.
- Document whether partial field loading is viable inside `NSIncrementalStore` without surprising property access semantics.
