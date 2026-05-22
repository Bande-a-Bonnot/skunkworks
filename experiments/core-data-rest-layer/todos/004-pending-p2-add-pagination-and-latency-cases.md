---
status: pending
priority: p2
issue_id: "004"
tags: [rest, pagination, latency]
dependencies: ["002"]
---

# Add Pagination and Latency Cases

Extend the embedded server spike beyond the first sync/edit/conflict path.

## Acceptance Criteria

- Server can return paginated task responses.
- Client/projection layer handles at least two pages deterministically.
- Server can inject latency for one endpoint in tests.
- Findings document which REST semantics remain visible above Core Data.
