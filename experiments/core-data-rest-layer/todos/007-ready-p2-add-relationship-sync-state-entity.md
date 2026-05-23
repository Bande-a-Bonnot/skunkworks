---
status: ready
priority: p2
issue_id: "007"
tags: [core-data, custom-store, pagination, sync-state]
dependencies: ["006"]
---

# Add Relationship Sync State Entity

Represent remote relationship completeness inside the custom-store Core Data model without reverting to a projection sync layer.

## Acceptance Criteria

- Add a managed entity for per-relationship remote load state, likely `CDRemoteRelationshipState`.
- Store updates state when `Project.tasks` relationship faulting walks paginated REST responses.
- Tests can inspect whether `Project.tasks` is complete, which pagination strategy was used, and basic fetched-count metadata.
- Document whether this makes REST-backed relationship faults more app-ergonomic or just adds sync-layer complexity back under another name.
