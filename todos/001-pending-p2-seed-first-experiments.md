---
status: pending
priority: p2
issue_id: "001"
tags: [experiments, catalog]
dependencies: []
---

# Seed First Experiments

Add the first real experiment directories under `experiments/` and update the experiment catalog.

## Acceptance Criteria

- At least one non-template experiment exists under `experiments/<slug>/`.
- Each seeded experiment has a README explaining what it is, status, and how to run or inspect it.
- `experiments/README.md` lists the seeded experiment(s).
- `docs/HANDOFF.md` is updated with the new experiment status.

## Notes

This is intentionally P2: the repo scaffold is useful immediately, but it becomes a real skunkworks once the first oddities land.
