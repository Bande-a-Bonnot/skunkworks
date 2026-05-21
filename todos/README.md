# Todos

Tracked follow-up work for Skunkworks.

## Filename Format

```text
NNN-status-priority-short-slug.md
```

Examples:

```text
001-pending-p2-seed-first-experiments.md
014-done-p3-fix-template-copy-command.md
```

## Frontmatter

```yaml
---
status: pending|ready|done|deferred
priority: p1|p2|p3
issue_id: "001"
tags: [repo]
dependencies: []
---
```

## Statuses

- `pending` — known work, not ready or not selected.
- `ready` — enough context exists to start.
- `done` — completed; keep the file as history.
- `deferred` — intentionally postponed.

Update `docs/HANDOFF.md` when opening, closing, or materially changing todos.
