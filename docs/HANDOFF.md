# Skunkworks Session Handoff

**URN:** `skunkworks::local::docs::handoff::019e4c5b-d963-7fda-96c7-1f399cdad092`  
**Last updated:** 2026-05-21  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` at the start of every Skunkworks session.

---

## Purpose

Skunkworks is the lightweight home for weird / fun / useless / interesting / unnamed experiments. The repo should make experiments easy to start, easy to find later, and easy to abandon or graduate without dragging the rest of the repository with them.

The guiding balance: enough structure for discoverability and handoff, not enough structure to suffocate play.

## Startup Checklist

1. Read `AGENTS.md` and this file.
2. Check the live repo state:
   ```bash
   git status --short --untracked-files=all
   git log --date=short --pretty=format:'%h %ad %s' -12
   ```
3. Review todo state:
   ```bash
   find todos -maxdepth 1 -type f -name '*.md' | sort
   ```
4. If working inside an experiment, read `experiments/<slug>/README.md` and any nested `AGENTS.md`.
5. Update this handoff when setup, todo state, or experiment status changes materially.

## Current State

Initial repo scaffolding has been created:

- `AGENTS.md` with repo-specific agent instructions.
- `README.md` with the repo purpose and quick-start layout.
- `docs/` with handoff plus category directories and initial repo-shape brainstorm.
- `todos/` with todo conventions and initial follow-up tasks.
- `experiments/` with a README, copyable `_template/`, and two seeded Core Data experiment directories.
- `docs/runbooks/create-experiment.md` and `docs/runbooks/graduate-or-archive-experiment.md` for common lifecycle tasks.
- `.gitignore` for common local/generated/secret files.

Seeded experiments:

- `experiments/core-data-rest-layer/` — Core Data as an object graph/change-tracking layer over REST APIs.
- `experiments/core-data-graph-db/` — graph database primitives and algorithms, including Dijkstra, using Core Data.

Existing root `nohup.out` was present before scaffold work and should remain untracked/ignored unless the user asks to clean it.

## Current Branch / Git Snapshot

Last inspected during scaffold setup:

```text
branch: main
remote: https://github.com/Bande-a-Bonnot/skunkworks
pre-existing untracked: nohup.out
```

Run `git status --short --untracked-files=all` for the current truth before making changes.

## Todo Snapshot

Current todos:

- `001` — `todos/001-done-p2-seed-first-experiments.md`: completed by seeding the first two Core Data experiments.
- `002` — `todos/002-pending-p2-spike-core-data-rest-layer.md`: create the first runnable REST-layer spike.
- `003` — `todos/003-pending-p2-spike-core-data-graph-db.md`: create the first runnable graph database spike.

## Repository Decisions

- Experiment roots live under `experiments/<slug>/`.
- `experiments/_template/` is intentionally committed as a copyable starting point.
- Cross-experiment docs use the sibling-project pattern:
  - `docs/brainstorms/`
  - `docs/plans/`
  - `docs/solutions/`
  - `docs/runbooks/`
- Todo records live as markdown files in `todos/` with frontmatter.
- No monorepo-level build system has been chosen. Experiments may use their own local tooling.

## Likely Next Actions

1. Pick one Core Data experiment and create its first runnable Swift spike.
2. Decide whether `experiments/README.md` should stay a manual catalog, become generated, or both.
3. Add a small script only if experiment indexing becomes annoying by hand.
4. Create plans only for experiments that are more than a quick toy.

## Notes for Future Agents

- Keep the root small. If a tool, package manager, or app framework is specific to one experiment, put it inside that experiment directory.
- Be honest in experiment status. `abandoned` and `useless but delightful` are valid outcomes.
- If an experiment graduates into its own repo, leave a short tombstone README in its old directory with the new location and final status.
