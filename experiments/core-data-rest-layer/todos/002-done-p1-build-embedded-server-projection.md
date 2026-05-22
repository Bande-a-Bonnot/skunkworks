---
status: done
priority: p1
issue_id: "002"
tags: [swift, core-data, rest, embedded-server]
dependencies: ["001"]
---

# Build Embedded Server Projection Spike

Implement the first runnable harness described in `docs/plans/2026-05-22-core-data-rest-layer-first-spike-plan.md`.

## Acceptance Criteria

- Swift package or app harness exists locally in this experiment directory.
- Tests start an embedded REST server bound to `127.0.0.1:0`.
- Server exposes at least:
  - `GET /projects`
  - `GET /projects/{projectID}/tasks`
  - `PATCH /tasks/{taskID}`
- URLSession client fetches from the embedded server.
- Core Data projection models `Project` and `Task` with relationships and remote version metadata.
- Sync pulls server state into Core Data.
- A local task edit is pushed to the server and clears dirty state on success.
- A stale local edit records conflict state when the server version has advanced.
- Findings are documented in README, handoff, or `docs/solutions/`.
