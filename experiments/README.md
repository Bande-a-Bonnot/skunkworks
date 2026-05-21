# Experiments

One directory per experiment. Keep experiments self-contained and documented enough that Future You can rediscover what happened.

## Catalog

| Slug | Status | Description |
|------|--------|-------------|
| `_template` | template | Copyable starter for new experiments. |

## Status Vocabulary

Use whichever label is honest:

- `idea` — not built yet.
- `spike` — exploratory implementation in progress.
- `working` — runnable and currently interesting.
- `paused` — not active, but worth keeping.
- `abandoned` — intentionally stopped.
- `graduated` — moved to its own repo/project.
- `useless-but-delightful` — success, somehow.

## Creating a New Experiment

```bash
slug="my-weird-thing"
cp -R experiments/_template "experiments/$slug"
```

Then edit `experiments/$slug/README.md` and update the catalog above.
