---
status: ready
priority: p1
issue_id: "005"
tags: [experiment, visionos, xcode, realitykit]
dependencies: ["004"]
---

# Wrap viewer in a runnable visionOS app bundle

## Goal

Turn the `FourDRayVisionViewer` SwiftPM/RealityKit prototype into a real visionOS app bundle that can run in the visionOS simulator or on Vision Pro hardware.

## Acceptance Criteria

- Add a local Xcode visionOS app project or another reproducible app-bundle build path inside this experiment directory.
- Reuse the existing viewer code or factor it into a shared target so the app displays the same projection-volume point cloud.
- Verify with either:
  - `xcodebuild` against an installed visionOS simulator destination, or
  - an actual Vision Pro run.
- Document the exact run command / Xcode scheme / destination.
- Update `README.md`, `docs/HANDOFF.md`, and findings with simulator/device status.

## Notes

Current state: the visionOS 26.2 simulator runtime is installed, and the SwiftPM viewer executable builds for the generic visionOS simulator destination:

```bash
cd experiments/vision-pro-4d-raytracer
xcodebuild -scheme FourDRayVisionViewer \
  -sdk xrsimulator \
  -destination 'generic/platform=visionOS Simulator' \
  build
```

A local simulator exists:

```text
Skunkworks Vision Pro (4A3E657D-C0F0-4F5D-B041-FE556B29DFDC)
```

This todo remains open because the viewer is still a SwiftPM executable prototype, not a fully wrapped app bundle that has been installed/launched in the simulator.
