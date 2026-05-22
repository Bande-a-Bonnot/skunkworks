# Core Data REST Layer — Agent Instructions

This experiment explores Core Data as an object graph / identity / change-tracking layer over REST APIs.

## Start Here

1. Read this file.
2. Read `docs/HANDOFF.md` for current state and next actions.
3. Read `README.md` and `docs/initial-questions.md` before changing code or plans.
4. Check live state from the repo root:
   ```bash
   git status --short --untracked-files=all
   ```
5. Review local todos in `todos/`.

## Experiment Boundary

- Keep all experiment-specific code, docs, fixtures, generated files, and package manifests inside `experiments/core-data-rest-layer/`.
- Do not add root-level package managers or build systems for this experiment.
- If shared repo docs need updates, update root `docs/HANDOFF.md` too.

## Technical Direction

- Prefer the first spike to be concrete and small.
- Do **not** start by building a generic REST ORM.
- Use an embedded local REST server for the first runnable spike so tests exercise real HTTP semantics.
- Treat REST as remote source of truth with its own semantics, not as SQL-over-HTTP.
- Compare approaches honestly:
  - local materialized projection;
  - custom persistent store;
  - hybrid.
- Make loading, errors, conflicts, stale reads, and pagination explicit in findings.

## Documentation

- `docs/HANDOFF.md` — rolling handoff for this experiment.
- `docs/initial-questions.md` — current question bank.
- `docs/plans/` — concrete implementation plans.
- `docs/brainstorms/` — fuzzy design exploration.
- `docs/solutions/` — reusable findings.
- `todos/` — local experiment tasks.

Update `docs/HANDOFF.md` before context compaction or at meaningful session boundaries.

## Verification

Until a runnable harness exists, verification is documentation/catalog consistency. Once code exists, document the smallest useful command in `README.md` and this handoff.
