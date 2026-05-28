---
status: ready
priority: p1
issue_id: "001"
tags: [experiment, math, metal, visionos]
dependencies: []
---

# Define 4D camera and projection model

## Goal

Choose the first camera/projection model for a 4D raytracer that will eventually be viewed binocularly on Vision Pro.

## Acceptance Criteria

- Define how a 3D/VR observer is embedded in 4D.
- Define how each eye generates 4D rays.
- Decide whether the first Metal output is a per-eye 2D texture, a 3D texture/volume, or a proxy geometry/point representation.
- Include formulas for ray generation, hypersphere intersection, hyperplane intersection, and 4D reflection.
- Add at least a tiny CPU-side check or pseudocode plan for validating the formulas before shader work.

## Notes

Keep the first model simple and honest. It is fine to fix the observer at `w = 0` and add `w` controls later, as long as rays and bounces can travel in all four dimensions.
