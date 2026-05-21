# Skunkworks Repo Shape Brainstorm

**Date:** 2026-05-21  
**Status:** captured as initial scaffold direction

## Seed Prompt

Create a repo regrouping all the weird / fun / useless / interesting / what-is-this-called / find-something-better experiments, one-off or otherwise. Use a dedicated `experiments/` subdirectory, each experiment in its own nested directory.

## Direction

Skunkworks should be a low-friction lab, not a product monorepo. The root should provide:

- discoverability;
- handoff continuity;
- experiment lifecycle conventions;
- enough hygiene to avoid future archaeology pain.

Each experiment should own its mess locally.

## Non-Goals

- One root build system for every experiment.
- Heavy architecture rules before an experiment earns them.
- Forcing every toy to become a plan.
- Pretending abandoned ideas are failures.

## Useful Tensions

- Structure vs spontaneity: root conventions, local freedom.
- Catalog vs junk drawer: experiments should be findable, but not polished prematurely.
- Graduation vs accumulation: if something becomes serious, move it out or leave a tombstone.

## Initial Decision

Use:

```text
experiments/<slug>/
```

for all experiment contents, plus a copyable `experiments/_template/` with a README skeleton and optional nested `AGENTS.md`.
