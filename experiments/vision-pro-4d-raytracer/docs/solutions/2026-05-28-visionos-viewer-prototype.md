# visionOS Viewer Prototype Findings

**Date:** 2026-05-28  
**Status:** RealityKit prototype code added; simulator/device run not verified on this machine

## What Exists

`FourDRayVisionViewer` is a Swift Package executable target with a visionOS-specific SwiftUI/RealityKit implementation:

```text
Sources/FourDRayVisionViewer/
├── FourDRayVisionViewerApp.swift
└── PointCloudSample.swift
```

On visionOS, it creates a volumetric window containing a RealityKit point-cloud proxy for the 4D-to-3D projection volume. Points preserve the current projection-volume coordinate semantics:

```text
x = u
y = v, flipped so display-up is positive
z = ana
```

The viewer uses a compact CPU mirror of the current Metal probe scene at `16 x 16 x 8` points (`2048` points) so the first RealityKit pass is light enough to inspect. The Metal probe still exports the higher-resolution `64 x 64 x 32` PLY point cloud separately.

On non-visionOS hosts, the target compiles as a small fallback executable that prints run instructions:

```bash
cd experiments/vision-pro-4d-raytracer
swift run FourDRayVisionViewer
```

## Verification

Passed on 2026-05-28:

```bash
cd experiments/vision-pro-4d-raytracer
swift run FourDRayVisionViewer
swift test
swift run FourDRayProbe
```

The visionOS branch was syntax/type checked directly against the XR simulator SDK with:

```bash
cd experiments/vision-pro-4d-raytracer
SDK=$(xcrun --sdk xrsimulator --show-sdk-path)
mkdir -p tmp/vision-compile-check
xcrun swiftc \
  -target arm64-apple-xros2.0-simulator \
  -sdk "$SDK" \
  -parse-as-library \
  Sources/FourDRayVisionViewer/PointCloudSample.swift \
  Sources/FourDRayVisionViewer/FourDRayVisionViewerApp.swift \
  -o tmp/vision-compile-check/FourDRayVisionViewer
```

`xcodebuild -scheme FourDRayVisionViewer -sdk xrsimulator -destination 'generic/platform=visionOS Simulator' build` could not run here because Xcode reported no eligible visionOS destination despite the XR simulator SDK being present. So this is not yet simulator/device-verified as an app bundle.

## Current Limitation

This is a native visionOS RealityKit prototype path, not a polished Xcode app project. The next step should wrap the viewer in a real visionOS app bundle/project and run it in the simulator or on physical Vision Pro hardware.
