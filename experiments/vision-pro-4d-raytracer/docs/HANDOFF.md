# Vision Pro 4D Raytracer Handoff

**URN:** `skunkworks::local::experiment::vision-pro-4d-raytracer::handoff::019e6610-a6d0-7318-8de1-0abc7727b861`  
**Last updated:** 2026-05-28  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on this experiment.

---

## Purpose

Explore a 4D raytracer where rays, surfaces, normals, lighting, and reflection operate in four spatial dimensions, then project the result into a binocular 3D/visionOS experience.

## Current State

- `spike` experiment.
- Swift package exists with CPU-side 4D ray, primitive, reflection, and camera checks.
- `FourDRayProbe` Metal executable renders a `64 x 64 x 32` 3D projected radiance volume and writes a middle-`ana` PPM debug slice.
- Camera/projection model v0 is documented in `docs/solutions/2026-05-26-camera-projection-model.md`.
- Metal probe findings are documented in `docs/solutions/2026-05-28-metal-probe-findings.md`.
- Todos `001` and `002` are done; next ready todo is `003`, the Vision Pro/spatial volume viewer path.

## Working Direction

Build a spatial viewer for the Metal-generated 3D projection volume.

Current GPU demo:

1. Scene: hypersphere plus one or two hyperplanes in 4D.
2. Ray model: `origin4 + t * direction4` with 4D-normalized directions.
3. Shading: normal visualization and one-bounce mirror reflection using 4D dot products.
4. Output: 3D texture/volume over `(u, v, ana)`, currently exported as one PPM slice for debug.

## Local Todos

- `001` — `todos/001-done-p1-define-4d-camera-projection.md` — done.
- `002` — `todos/002-done-p1-port-cpu-core-to-metal.md` — done.
- `003` — `todos/003-ready-p1-build-vision-pro-volume-viewer.md` — ready.

## Open Questions

- Should the first projection produce a true 3D volume that Vision Pro views stereoscopically, or should each eye directly render a 2D image from a binocular 4D camera?
- How should a 3D observer/camera be embedded in 4D: fixed `w`, animated `w`, or full 4D orientation basis?
- What is the most legible first primitive set: hyperspheres, hyperplanes, tesseract SDFs, or 4D fractal-ish distance fields?
- Is the first implementation a macOS Metal compute prototype, a Swift package with CPU tests, or a visionOS app from day one?

## Verification

Run from this experiment directory:

```bash
swift test
swift run FourDRayProbe
```

Expected: `FourDRayCoreTests` passes, and `FourDRayProbe` writes `tmp/four-d-ray-probe-ana-mid-slice.ppm`.

## Next Action

Work `todos/003-ready-p1-build-vision-pro-volume-viewer.md`: decide and implement the first spatial/visionOS viewer path for the generated 3D projection volume.
