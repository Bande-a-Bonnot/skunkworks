# Skunkworks

A low-friction lab for weird, fun, useless, interesting, what-is-this-even-called, find-something-better experiments.

## Start Here

1. Read this file.
2. Read `docs/HANDOFF.md` for current state, open questions, and recent changes.
3. Check live repository state before acting:
   ```bash
   git status --short --untracked-files=all
   git log --date=short --pretty=format:'%h %ad %s' -12
   ```
4. If touching an experiment, read that experiment's own `README.md` first.

## Shape of the Repo

- `experiments/` — one directory per experiment. Each experiment owns its code, notes, assets, and local conventions.
- `docs/` — cross-experiment docs: plans, brainstorms, reusable learnings, runbooks, and this repo's handoff.
- `todos/` — tracked follow-up work as small markdown files.

Experiments may be one-off toys, prototypes, research spikes, joke tools, half-baked ideas, or serious seeds that might graduate into their own repo later.

## Experiment Rules

- Keep each experiment contained in `experiments/<slug>/` unless it intentionally graduates.
- Add a short `README.md` to every experiment before or with the first code drop.
- If an experiment has special setup, commands, credentials, or hazards, document them locally in its README.
- Prefer disposable scaffolding over shared frameworks until duplication hurts.
- Do not let one experiment's dependency manager, generated files, or build artifacts leak into repo root.
- If an experiment becomes substantial, add a nested `AGENTS.md` with more specific instructions.

## Suggested Experiment README Sections

- What / why
- Status
- Quick start
- Notes / findings
- Next ideas
- Cleanup / graduation criteria

Use `experiments/_template/` as a copyable starting point.

## Documentation Conventions

- `docs/HANDOFF.md` — rolling agent handoff; update before context compaction or at meaningful session boundaries.
- `docs/brainstorms/` — fuzzy product/idea exploration.
- `docs/plans/` — concrete implementation plans.
- `docs/solutions/` — reusable learnings and solved problems.
- `docs/runbooks/` — operational recipes for repeatable tasks.

When picking up meaningful work from a brainstorm or roadmap, create or update a plan first. When a plan changes due to discoveries, add a dated addendum instead of leaving stale instructions.

## Todo Conventions

Todo files live in `todos/` and use:

```text
NNN-status-priority-short-slug.md
```

Frontmatter:

```yaml
---
status: pending|ready|done|deferred
priority: p1|p2|p3
issue_id: "001"
tags: [repo]
dependencies: []
---
```

Update `docs/HANDOFF.md` when opening, closing, or materially changing todos.

## Development Conventions

- Favour `rg`, `fd`, and `ast-grep` for research when available.
- Commit early and atomically.
- Use Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `test:`, `refactor:`, etc.
- Use TDD when the experiment's shape justifies tests; otherwise document manual verification honestly.
- Run the smallest useful check before declaring work done.
- Use UUIDv7 for durable IDs where IDs are needed.

## Git

Set `SSH_AUTH_SOCK` before git operations requiring authentication:

```bash
export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
```

## Safety / Hygiene

- Keep credentials out of git. Use local `.env` files, gitignored `credentials/`, or documented external secret stores.
- Generated outputs belong in local ignored directories (`tmp/`, `dist/`, `build/`, etc.) unless intentionally committed as artifacts.
- Preserve unrelated untracked files unless the user explicitly asks to clean them.
