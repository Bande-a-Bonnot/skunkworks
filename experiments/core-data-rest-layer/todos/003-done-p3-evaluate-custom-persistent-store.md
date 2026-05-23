---
status: done
priority: p3
issue_id: "003"
tags: [core-data, custom-store, research]
dependencies: ["001", "002"]
---

# Evaluate Custom Persistent Store

After the embedded-server projection spike, decide whether a custom Core Data persistent store is worth exploring.

Decision: yes. The projection spike answered the wrong/boring architecture. A minimal `NSIncrementalStore` spike now proves Core Data fetch, relationship faulting, and save can call REST directly.

## Acceptance Criteria

- Summarize what the embedded-server projection spike taught.
- Identify the smallest custom-store slice worth attempting, if any.
- Document reasons to proceed or stop.
- Open a follow-up todo only if the path still seems useful.
