# New Skunkwork Experiment Cookbook

Use this playbook when creating a new experiment for this repository.

The goal is not bureaucracy. The goal is to make every strange idea easy to restart after three weeks, three months, or three agents.

## Principle

Each experiment gets a self-contained lab bench:

```text
experiments/<slug>/
├── AGENTS.md
├── README.md
├── docs/
│   ├── HANDOFF.md
│   ├── README.md
│   ├── brainstorms/
│   ├── plans/
│   ├── runbooks/
│   └── solutions/
└── todos/
    └── README.md
```

Add code only after the lab bench says what the first question is.

## 1. Pick the Slug

Use short kebab-case:

```bash
slug="my-weird-thing"
```

Good slugs are specific enough to remember and boring enough to type.

## 2. Copy the Template

```bash
cp -R experiments/_template "experiments/$slug"
```

Then immediately edit:

- `experiments/$slug/README.md`
- `experiments/$slug/AGENTS.md`
- `experiments/$slug/docs/HANDOFF.md`

## 3. Write the Experiment README First

Answer, briefly:

1. What is this?
2. Why is it interesting/funny/useful/useless?
3. What is the first concrete question?
4. How would someone run or inspect it?
5. What counts as abandon/archive/graduation?

Use honest statuses: `idea`, `spike`, `working`, `paused`, `abandoned`, `graduated`, `useless-but-delightful`.

## 4. Write Local Agent Instructions

`AGENTS.md` should tell future agents:

- what to read first;
- where the boundary is;
- what not to accidentally generalize;
- how to verify work;
- which files to update before stopping.

Keep root rules in root `AGENTS.md`; keep experiment-specific rules local.

## 5. Create the Local Handoff

`docs/HANDOFF.md` should include:

- purpose;
- current state;
- local todos;
- open questions;
- verification status;
- exact next action.

Use a UUIDv7 URN if a durable ID is useful:

```text
skunkworks::local::experiment::<slug>::handoff::<uuidv7>
```

## 6. Create Local Todos

Start with at least one real next step:

```text
todos/001-ready-p1-write-first-spike-plan.md
```

Use frontmatter:

```yaml
---
status: pending|ready|done|deferred
priority: p1|p2|p3
issue_id: "001"
tags: [experiment]
dependencies: []
---
```

Prefer local todos for experiment work. Use root `todos/` only for repo-level coordination or cross-experiment tasks.

## 7. Update the Catalog

Add the experiment to `experiments/README.md`:

```markdown
| `my-weird-thing` | idea | One-line description. |
```

## 8. Update Root Handoff When It Matters

Update root `docs/HANDOFF.md` when:

- a new experiment is added;
- an experiment changes status;
- repo-wide conventions change;
- a future agent needs cross-experiment context.

## 9. Only Then Add Code

For the first code spike:

- keep tooling local to `experiments/<slug>/`;
- document the smallest useful command;
- avoid root-level dependencies until multiple experiments truly need them;
- prefer boring scaffolding and interesting questions.

## 10. Stop Cleanly

Before ending a meaningful session:

1. Run the smallest useful check.
2. Update local `docs/HANDOFF.md`.
3. Update local todos.
4. Update `experiments/README.md` if status changed.
5. Update root `docs/HANDOFF.md` if cross-experiment context changed.
6. Commit atomically with a Conventional Commit message.

## Quick Checklist

- [ ] Directory under `experiments/<slug>/`
- [ ] `README.md`
- [ ] `AGENTS.md`
- [ ] `docs/HANDOFF.md`
- [ ] `docs/README.md`
- [ ] `todos/README.md`
- [ ] At least one local todo
- [ ] Catalog updated
- [ ] Root handoff updated if needed
