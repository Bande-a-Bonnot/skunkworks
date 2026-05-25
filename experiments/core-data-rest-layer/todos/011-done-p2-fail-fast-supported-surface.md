---
status: done
priority: p2
issue_id: "011"
tags: [core-data, custom-store, errors, tests]
dependencies: ["009"]
---

# Fail Fast Unsupported Core Data Surface

Add a small hardening pass so the REST-backed `NSIncrementalStore` rejects unsupported Core Data fetch/save shapes instead of silently pretending to support them.

## Acceptance Criteria

- Unsupported fetch predicates fail with a typed `RESTIncrementalStoreError`.
- Unsupported fetch limits/count-style result shapes fail with a typed `RESTIncrementalStoreError`.
- Unsupported domain inserts/deletes fail during save before any REST write is attempted.
- Currently supported managed-object fetches, simple sorts, relationship faults, direct task saves, and pending-change flows keep passing.
- Document the supported surface boundary.
