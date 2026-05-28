# Vision Pro 4D Raytracer Handoff

**URN:** `skunkworks::local::experiment::vision-pro-4d-raytracer::handoff::019e6610-a6d0-7318-8de1-0abc7727b861`  
**Last updated:** 2026-05-26  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on this experiment.

---

## Purpose

Explore a 4D raytracer where rays, surfaces, normals, lighting, and reflection operate in four spatial dimensions, then project the result into a binocular 3D/visionOS experience.

## Current State

- Scaffolded as an `idea` experiment.
- No runnable code yet.
- Local plan exists at `docs/plans/2026-05-26-first-spike-plan.md`.
- First todo is ready: define the camera/projection model and CPU-check the core 4D math.

## Working Direction

Start with math and representation, then build the smallest Metal-backed proof.

Candidate first visible demo:

1. Scene: hypersphere plus one or two hyperplanes in 4D.
2. Ray model: `origin4 + t * direction4` with 4D-normalized directions.
3. Shading: normal visualization and one-bounce mirror reflection using 4D dot products.
4. Output: either a 3D texture/volume for stereoscopic inspection or direct per-eye render targets.

## Local Todos

- `001` — `todos/001-ready-p1-define-4d-camera-projection.md`

## Open Questions

- Should the first projection produce a true 3D volume that Vision Pro views stereoscopically, or should each eye directly render a 2D image from a binocular 4D camera?
- How should a 3D observer/camera be embedded in 4D: fixed `w`, animated `w`, or full 4D orientation basis?
- What is the most legible first primitive set: hyperspheres, hyperplanes, tesseract SDFs, or 4D fractal-ish distance fields?
- Is the first implementation a macOS Metal compute prototype, a Swift package with CPU tests, or a visionOS app from day one?

## Verification

No code exists yet. Current verification is structural/document review only.

## Next Action

Work `todos/001-ready-p1-define-4d-camera-projection.md`: write down the camera/projection choice, derive the first ray generation formulas, and CPU-check hypersphere intersection plus 4D reflection before creating a Metal/visionOS project.
