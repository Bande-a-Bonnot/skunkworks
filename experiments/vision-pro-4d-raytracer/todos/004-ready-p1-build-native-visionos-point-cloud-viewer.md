---
status: ready
priority: p1
issue_id: "004"
tags: [experiment, visionos, realitykit, viewer]
dependencies: ["003"]
---

# Build native visionOS point-cloud viewer

## Goal

Create the first native Vision Pro/visionOS viewer for the 4D-to-3D projection volume, using the PLY/point-cloud export path or a direct in-app volume buffer.

## Acceptance Criteria

- Add a local visionOS app target/project or clearly documented RealityKit prototype path inside this experiment directory.
- Display the projected volume as spatial data: point cloud, instanced voxels, particles, or another explicit 3D proxy.
- Preserve coordinate semantics: `x = u`, `y = v`, `z = ana` unless a documented transform is applied.
- Document whether verification used visionOS simulator, physical Vision Pro hardware, or macOS-only build checks.
- Update README and `docs/HANDOFF.md` with exact run/open instructions.

## Notes

The current stepping stone is:

```bash
cd experiments/vision-pro-4d-raytracer
swift run FourDRayProbe
```

which writes:

```text
tmp/four-d-ray-probe-volume-point-cloud.ply
```

A native viewer can either consume that file or share the Metal volume generation path directly.
