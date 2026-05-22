---
status: pending
priority: p2
issue_id: "006"
tags: [benchmark, statistics]
dependencies: ["005"]
---

# Add Repeated Benchmark Runs

Make benchmark output less noisy by supporting repeated runs and summary statistics.

## Acceptance Criteria

- Benchmark accepts a repeat count, e.g. `--runs 5`.
- Output reports at least median; p95 would be useful if enough runs exist.
- Docs explain whether seed/setup time is included per run.
- Findings are updated or a new solution doc is added.
