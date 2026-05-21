# Graduate or Archive an Experiment

Use this when an experiment is no longer just a Skunkworks item.

## Graduation

An experiment can graduate when it needs its own issue tracker, releases, CI, secrets, product docs, or repo-level build system.

1. Create/move to the new home.
2. Leave a tombstone README at `experiments/<slug>/README.md` with:
   - final status: `graduated`;
   - new repo/path;
   - what shipped or why it mattered;
   - date of graduation.
3. Update `experiments/README.md` catalog.
4. Close/update related todos.
5. Update `docs/HANDOFF.md`.

## Archival / Abandonment

Abandoning an experiment is a valid outcome.

1. Mark status as `abandoned` or `paused` in the experiment README.
2. Capture any reusable findings in `docs/solutions/` if worth remembering.
3. Update `experiments/README.md` and related todos.
4. Keep or delete bulky generated artifacts according to git hygiene; do not delete user-created untracked files without explicit confirmation.
