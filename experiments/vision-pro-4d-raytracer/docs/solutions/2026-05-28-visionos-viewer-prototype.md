# visionOS Viewer Prototype Findings

**Date:** 2026-05-28  
**Status:** RealityKit prototype code added; visionOS simulator runtime installed; generic simulator build verified; app-bundle run still not verified

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

After installing the visionOS simulator platform/runtime with:

```bash
xcodebuild -downloadPlatform visionOS
```

Xcode reports:

```text
visionOS 26.2 (26.2 - 23N301) - com.apple.CoreSimulator.SimRuntime.xrOS-26-2
```

A local simulator was created:

```text
Skunkworks Vision Pro (4A3E657D-C0F0-4F5D-B041-FE556B29DFDC)
```

The SwiftPM executable target now builds for the generic visionOS simulator destination:

```bash
cd experiments/vision-pro-4d-raytracer
xcodebuild -scheme FourDRayVisionViewer \
  -sdk xrsimulator \
  -destination 'generic/platform=visionOS Simulator' \
  build
```

Result on 2026-05-28: `BUILD SUCCEEDED`.

## Current Limitation

This is a native visionOS RealityKit prototype path that builds for the visionOS simulator SDK, but it is not yet packaged as a polished app project or run in a simulator window. The next step should wrap the viewer in a real visionOS app bundle/project and run it in the simulator or on physical Vision Pro hardware.
