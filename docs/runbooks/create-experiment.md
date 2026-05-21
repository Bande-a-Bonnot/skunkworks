# Create a New Experiment

Use this when adding a new experiment under `experiments/`.

## Steps

1. Pick a short kebab-case slug:
   ```bash
   slug="my-weird-thing"
   ```
2. Copy the template:
   ```bash
   cp -R experiments/_template "experiments/$slug"
   ```
3. Edit `experiments/$slug/README.md`:
   - name and one-line description;
   - honest status;
   - quick-start or inspection notes;
   - findings / next ideas.
4. Remove `experiments/$slug/AGENTS.md` unless the experiment needs local agent instructions.
5. Update the catalog in `experiments/README.md`.
6. If the experiment creates follow-up work, add or update a todo in `todos/`.
7. Update `docs/HANDOFF.md` with any material context.

## Checks

At minimum:

```bash
git status --short --untracked-files=all
```

If the experiment has its own checks, run the smallest useful one and record the result in its README or handoff.
