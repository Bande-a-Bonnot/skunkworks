---
status: pending
priority: p2
issue_id: "002"
tags: [core-data, rest, swift]
dependencies: []
---

# Spike Core Data REST Layer

Create the first runnable spike for `experiments/core-data-rest-layer/`.

## Acceptance Criteria

- A minimal Swift harness exists in the experiment directory.
- The harness models a tiny remote domain, likely `Project` and `Task`.
- It starts an embedded local REST server for tests/demo usage.
- It syncs server data into or through Core Data.
- It demonstrates a local edit/change-tracking flow and stale-write conflict handling.
- Findings are recorded in the experiment README or a local docs file.

## Notes

Start concrete and small. Avoid building a generic REST ORM before learning where Core Data actually helps.
