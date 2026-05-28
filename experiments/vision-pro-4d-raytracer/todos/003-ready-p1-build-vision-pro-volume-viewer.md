---
status: ready
priority: p1
issue_id: "003"
tags: [experiment, visionos, metal, viewer]
dependencies: ["002"]
---

# Build first Vision Pro volume viewer path

## Goal

Turn the Metal-generated 3D projected radiance volume into something inspectable stereoscopically on Vision Pro or, as a stepping stone, in a documented macOS 3D viewer.

## Acceptance Criteria

- Decide the first viewer stack: visionOS RealityKit/SwiftUI, MetalKit, or a simpler macOS slice/volume inspector.
- Keep the 4D-to-3D projection volume explicit; do not collapse back to only a flat 2D image.
- Display or export multiple `ana` slices, a point cloud, volume proxy geometry, or a true 3D texture visualization.
- Document simulator vs device assumptions.
- Update README quick start and `docs/HANDOFF.md` with the viewer command or Xcode run instructions.

## Notes

The current `FourDRayProbe` writes a 3D texture and exports only the middle `ana` slice as `tmp/four-d-ray-probe-ana-mid-slice.ppm`. The next step is making that volume spatially inspectable.
