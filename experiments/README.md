# Experiments

One directory per experiment. Keep experiments self-contained and documented enough that Future You can rediscover what happened.

## Catalog

| Slug | Status | Description |
|------|--------|-------------|
| `vision-pro-4d-raytracer` | spike | Explore a Metal 4D raytracer with 4D bounces, 3D projection, and a binocular Vision Pro camera. |
| `core-data-rest-layer` | idea | Explore Core Data as an object graph/change-tracking layer over REST APIs instead of local/CloudKit persistence. |
| `core-data-graph-db` | spike | Implements graph primitives, BFS, Dijkstra, and benchmarks over Core Data managed objects vs snapshots. |
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
