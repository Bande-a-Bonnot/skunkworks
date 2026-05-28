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

Current state: the visionOS SwiftUI/RealityKit code compiles via direct `swiftc` against the XR simulator SDK, but `xcodebuild` could not find an eligible visionOS destination on this machine. Installing the full visionOS platform/runtime in Xcode may be required before this can be fully verified.
