# Skunkworks Session Handoff

**URN:** `skunkworks::local::docs::handoff::019e4c5b-d963-7fda-96c7-1f399cdad092`  
**Last updated:** 2026-05-22  
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
3. Review root todo state:
   ```bash
   find todos -maxdepth 1 -type f -name '*.md' | sort
   ```
4. If working inside an experiment, read that experiment's local `AGENTS.md` and `docs/HANDOFF.md`.
5. Update this handoff only for repo-level state, active experiment pointers, or skunkworks process changes. Keep experiment-specific detail in experiment-local handoffs.

## Repository State

Repo scaffold is in place:

- `AGENTS.md` — repo-level agent instructions.
- `README.md` — repo purpose and layout.
- `docs/` — repo-level handoff, brainstorms, plans, runbooks, and solutions.
- `docs/runbooks/new-skunkwork-experiment-cookbook.md` — playbook for new experiments.
- `experiments/` — one directory per experiment, plus `_template/`.
- `todos/` — root/cross-experiment todo records.
- `.gitignore` — common local/generated/secret files.

No repo-level build system is chosen. Experiments own their local tooling.

Existing root `nohup.out` was present from before setup and is ignored. Do not delete it unless the user asks.

## Active / Parked Experiments

Active / next up:

- `experiments/core-data-rest-layer/` — read `experiments/core-data-rest-layer/docs/HANDOFF.md`.

Parked / optional follow-up:

- `experiments/core-data-graph-db/` — read `experiments/core-data-graph-db/docs/HANDOFF.md`.

Catalog:

- `experiments/README.md`

## Root Todo Snapshot

Root todos track repo-level or cross-experiment work only. Experiment-specific work belongs in each experiment's local `todos/` directory.

- `001` — `todos/001-done-p2-seed-first-experiments.md`
- `002` — `todos/002-done-p2-spike-core-data-rest-layer.md`
- `003` — `todos/003-done-p2-spike-core-data-graph-db.md`

## Repository Decisions

- Experiment roots live under `experiments/<slug>/`.
- Each experiment should have local `AGENTS.md`, `docs/HANDOFF.md`, docs sections, and local todos.
- `experiments/_template/` is intentionally committed as a copyable starting point.
- Root docs should stay about Skunkworks process/repo concerns, not detailed experiment implementation notes.
- Use experiment-local docs for detailed plans, findings, and handoffs.
- Todo records live as markdown files with frontmatter.

## Likely Next Actions

1. Continue `core-data-rest-layer` with local todo `005`: harden the real `NSIncrementalStore` REST path (conflicts/errors/pagination).
2. Keep root handoff minimal; update experiment-local handoff with implementation details.
3. Decide later whether `experiments/README.md` should stay a manual catalog, become generated, or both.

## Notes for Future Agents

- Keep the root small. If a tool, package manager, or app framework is specific to one experiment, put it inside that experiment directory.
- Be honest in experiment status. `abandoned` and `useless but delightful` are valid outcomes.
- If an experiment graduates into its own repo, leave a short tombstone README in its old directory with the new location and final status.
