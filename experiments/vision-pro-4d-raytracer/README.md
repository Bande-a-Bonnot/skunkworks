# Vision Pro 4D Raytracer

> A Metal-backed experiment in raytracing through four spatial dimensions, then projecting the result into a binocular 3D/visionOS viewing experience.

## Status

`spike` — scaffolded with CPU-side 4D ray/intersection/reflection checks; no Metal or visionOS target yet.

## Why

Raytracing is usually a 3D scene sampled by 2D camera rays. This experiment asks what happens if the world, rays, intersections, normals, and reflection all live in 4D, then we expose a 3D projection of that world to a stereoscopic viewer on Vision Pro.

The fun parts:

- rays travel in four dimensions, so bounces can change direction across `x/y/z/w`;
- surface normals and reflection laws are computed in 4D, not faked in 3D;
- the camera is binocular, but each eye may need a coherent embedding into 4D;
- Metal can do the heavy per-ray work while visionOS handles presence, scale, and stereo display.

## First Concrete Question

What is the smallest mathematically honest rendering model that can show a reflective 4D primitive, projected into a Vision Pro-friendly 3D representation?

Initial target: a Metal compute prototype that traces 4D rays against simple implicit primitives such as a 3-sphere/hypersphere and hyperplanes, applies 4D reflection, and writes either:

1. a 3D texture/volume that RealityKit can display stereoscopically, or
2. per-eye 2D render targets generated from a binocular 4D camera.

## Quick Start

Run the CPU math checks:

```bash
cd experiments/vision-pro-4d-raytracer
swift test
```

Inspect the active docs:

```bash
open docs/HANDOFF.md
open docs/solutions/2026-05-26-camera-projection-model.md
```

## Local Docs

- `AGENTS.md` — local agent instructions.
- `docs/HANDOFF.md` — current state and next action.
- `docs/plans/2026-05-26-first-spike-plan.md` — first spike plan.
- `docs/solutions/2026-05-26-camera-projection-model.md` — v0 camera/projection decision and formulas.
- `todos/` — local task records.

## Notes / Findings

Working assumptions for the first spike:

- A ray is `r(t) = origin4 + t * direction4`, with `origin4` and `direction4` in `R4`.
- Directions and normals are normalized in 4D.
- For an implicit 4D surface `F(p) = 0`, normal is `normalize(grad F(p))` in 4D.
- Perfect reflection is still `reflected = direction - 2 * dot(direction, normal) * normal`, but dot products and vectors are 4D.
- Projection is intentionally unresolved: direct per-eye 2D rendering and intermediate 3D-volume rendering are both candidates.

## Next Ideas

- [x] Define the 4D camera/projection model before building UI.
- [x] Prototype CPU-side intersection math for hypersphere + hyperplane.
- [ ] Port the minimal kernel to Metal compute.
- [ ] Build a 3D texture/volume output path for Vision Pro inspection.

## Cleanup / Graduation

Abandon if the math becomes too hand-wavy to distinguish from a normal shader toy.

Archive if the result is just notes and a few useful formulas.

Graduate if it becomes a runnable visionOS/Metal demo with a coherent 4D camera model, interactive navigation, and visually legible 4D reflections.
