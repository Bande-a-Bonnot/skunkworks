# First Spike Plan: 4D Metal Raytracer for Vision Pro

**Date:** 2026-05-26  
**Status:** draft

## Goal

Create the smallest prototype that proves the core idea is not just a 3D raytracer with an extra uniform: rays must move through 4D, intersect 4D surfaces, compute 4D normals, and reflect in 4D before projection into a Vision Pro-friendly view.

## Non-Goals

- Photorealism.
- A complete visionOS app before the math is clear.
- Complex asset loading.
- Physically perfect 4D optics beyond a coherent first model.

## Core Model

Use `float4` for 4D positions and directions.

Ray:

```text
r(t) = o4 + t d4, t >= 0, length(d4) = 1
```

Implicit surface:

```text
F(p4) = 0
n4 = normalize(grad F(p4))
```

Perfect reflection:

```text
d4' = d4 - 2 dot(d4, n4) n4
```

This is the same algebraic reflection formula as 3D, but it must use 4D vectors, 4D normals, and 4D dot products.

## First Primitives

1. Hypersphere / 3-sphere boundary:
   ```text
   F(p) = dot(p - c, p - c) - r^2
   normal = normalize(p - c)
   ```
2. Hyperplane:
   ```text
   F(p) = dot(n, p) + b
   normal = normalize(n)
   ```

These give closed-form intersections and easy normal checks.

## Projection Options to Decide

### Option A: Direct binocular 2D render targets

Each eye has a 4D origin. For each display pixel, generate one 4D ray using a 4D camera frame. This is closest to normal VR rendering, but it may hide the requested "projecting in 3D" aspect.

### Option B: 4D-to-3D projected radiance volume

Trace rays through a 3D lattice/sensor embedded in 4D and write a 3D texture or point cloud. Vision Pro then views this projected volume stereoscopically. This better matches "projecting in 3D" but costs more samples.

### Option C: Hybrid

Build a 3D proxy representation from 4D intersections, then render the proxy per-eye. This may be easiest for RealityKit but could become less raytracer-like.

## Suggested Milestones

1. **Math note / CPU checks**
   - Define camera basis.
   - Unit-test hypersphere intersection.
   - Unit-test 4D reflection preserves direction length and flips normal component.
2. **Metal compute toy**
   - One kernel, `float4` ray state, small primitive array.
   - Write normal/debug color to a texture or 3D texture.
3. **Projection viewer**
   - macOS/SwiftUI viewer first if faster, or visionOS if project setup is easy.
   - Keep the output format swappable.
4. **Vision Pro binocular mode**
   - Use per-eye transforms or RealityKit stereo presentation.
   - Document simulator vs hardware verification.

## First Deliverable

A short design note plus CPU test harness that answers:

- What exactly is the camera/projection model?
- Given one eye pose, how is a 4D ray generated?
- How is binocular separation represented in 4D?
- What is the first output artifact Metal writes?
