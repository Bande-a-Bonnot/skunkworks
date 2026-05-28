---
status: ready
priority: p1
issue_id: "002"
tags: [experiment, metal, rendering]
dependencies: ["001"]
---

# Port CPU ray core to a minimal Metal compute kernel

## Goal

Create the first Metal-backed renderer that traces the same v0 4D camera, hypersphere, hyperplane, and 4D reflection model validated by the CPU tests.

## Acceptance Criteria

- Add a local Metal shader/kernel that uses `float4` ray origin, direction, normals, and reflection.
- Produce a tiny 3D projected radiance volume or a documented temporary 2D debug texture.
- Keep the shader primitive set equivalent to the CPU core: hypersphere and hyperplane at minimum.
- Add a Swift-side harness or documented command to compile/run the kernel on macOS before visionOS UI work.
- Update `docs/HANDOFF.md` and README quick start with the command.

## Notes

The preferred first output is a 3D texture over `(u, v, ana)` so the 4D-to-3D projection remains explicit. A 2D texture is acceptable only as a short-lived debug stepping stone.
