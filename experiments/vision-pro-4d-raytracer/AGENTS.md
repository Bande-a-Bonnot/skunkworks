# Vision Pro 4D Raytracer Agent Notes

Local instructions for the 4D Metal/visionOS raytracing experiment.

## Start Here

1. Read this file.
2. Read `docs/HANDOFF.md`.
3. Read `README.md`.
4. Review local todos in `todos/`.
5. If touching code, read the active plan in `docs/plans/` first.
6. Check repo state from the repository root:
   ```bash
   git status --short --untracked-files=all
   ```

## Local Rules

- Keep all code, packages, Xcode projects, generated assets, and notes inside `experiments/vision-pro-4d-raytracer/`.
- Do not add repo-root package managers or shared build systems for this experiment.
- Treat the 4D math as part of the artifact: document formulas before hiding them in shaders.
- Prefer a tiny mathematically honest prototype over a flashy but ambiguous shader.
- Keep Vision Pro/visionOS assumptions explicit; note whether verification used simulator, macOS-only Metal, or actual hardware.
- Generated build output belongs in ignored local directories such as `.build/`, `DerivedData/`, `tmp/`, or `build/`.
- Update `docs/HANDOFF.md` before context compaction or meaningful session boundaries.
- If the experiment is abandoned, paused, or graduated, update this README and `../README.md` catalog.

## Verification

Until there is code, verification is document review only.

Once code exists, document the smallest useful command here and in `README.md`/`docs/HANDOFF.md`.
