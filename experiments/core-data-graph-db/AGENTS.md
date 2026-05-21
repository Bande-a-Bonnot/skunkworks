# Core Data Graph Database — Agent Instructions

This experiment explores graph database primitives and graph algorithms using Core Data as the storage/object-graph substrate.

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

- Keep all experiment-specific code, docs, fixtures, generated files, and package manifests inside `experiments/core-data-graph-db/`.
- Do not add root-level package managers or build systems for this experiment.
- If shared repo docs need updates, update root `docs/HANDOFF.md` too.

## Technical Direction

- Start with a tiny directed weighted graph.
- Model edges as first-class entities.
- Prefer a programmatic Core Data model for the first Swift package spike.
- Compare live managed-object traversal against value-snapshot adjacency traversal.
- Keep algorithm implementations readable before optimizing.
- Record where Core Data helps, where faulting/context boundaries hurt, and where a normal adjacency list is clearer.

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
