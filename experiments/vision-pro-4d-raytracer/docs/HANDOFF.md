# Vision Pro 4D Raytracer Handoff

**URN:** `skunkworks::local::experiment::vision-pro-4d-raytracer::handoff::019e6610-a6d0-7318-8de1-0abc7727b861`  
**Last updated:** 2026-05-28  
**Update this before context compaction or at the end of meaningful sessions.**

Read this after `AGENTS.md` when working on this experiment.

---

## Purpose

Explore a 4D raytracer where rays, surfaces, normals, lighting, and reflection operate in four spatial dimensions, then project the result into a binocular 3D/visionOS experience.

## Current State

- `spike` experiment.
- Swift package exists with CPU-side 4D ray, primitive, reflection, and camera checks.
- `FourDRayProbe` Metal executable renders a `64 x 64 x 32` 3D projected radiance volume and writes a middle-`ana` PPM slice, an 8-slice `ana` contact sheet, and a PLY point cloud.
- `FourDRayVisionViewer` SwiftPM executable contains a visionOS SwiftUI/RealityKit volumetric point-cloud prototype plus a macOS fallback message; the target builds for the generic visionOS simulator destination.
- Camera/projection model v0 is documented in `docs/solutions/2026-05-26-camera-projection-model.md`.
- Metal probe findings are documented in `docs/solutions/2026-05-28-metal-probe-findings.md`.
- Volume inspection/export path is documented in `docs/solutions/2026-05-28-volume-inspection-path.md`.
- visionOS viewer prototype notes are documented in `docs/solutions/2026-05-28-visionos-viewer-prototype.md`.
- visionOS 26.2 simulator runtime is installed. Local simulator: `Skunkworks Vision Pro (4A3E657D-C0F0-4F5D-B041-FE556B29DFDC)`.
- Todos `001` through `004` are done; next ready todo is `005`, wrapping the viewer in a launched/installed visionOS app bundle.

## Working Direction

Wrap the RealityKit viewer prototype in a runnable visionOS app bundle and verify it in the simulator or on hardware.

Current GPU demo:

1. Scene: hypersphere plus one or two hyperplanes in 4D.
2. Ray model: `origin4 + t * direction4` with 4D-normalized directions.
3. Shading: normal visualization and one-bounce mirror reflection using 4D dot products.
4. Output: 3D texture/volume over `(u, v, ana)`, exported as PPM slices/contact sheet and a PLY point cloud for spatial inspection; RealityKit prototype shows a compact in-app point cloud with the same coordinate semantics.

## Local Todos

- `001` — `todos/001-done-p1-define-4d-camera-projection.md` — done.
- `002` — `todos/002-done-p1-port-cpu-core-to-metal.md` — done.
- `003` — `todos/003-done-p1-build-vision-pro-volume-viewer.md` — done as contact-sheet + PLY export path.
- `004` — `todos/004-done-p1-build-native-visionos-point-cloud-viewer.md` — done as SwiftPM/RealityKit prototype path.
- `005` — `todos/005-ready-p1-wrap-viewer-in-visionos-app-bundle.md` — ready.

## Open Questions

- Should the first projection produce a true 3D volume that Vision Pro views stereoscopically, or should each eye directly render a 2D image from a binocular 4D camera?
- How should a 3D observer/camera be embedded in 4D: fixed `w`, animated `w`, or full 4D orientation basis?
- What is the most legible first primitive set: hyperspheres, hyperplanes, tesseract SDFs, or 4D fractal-ish distance fields?
- Is the first implementation a macOS Metal compute prototype, a Swift package with CPU tests, or a visionOS app from day one?

## Verification

Run from this experiment directory:

```bash
swift test
swift run FourDRayProbe
swift run FourDRayVisionViewer
xcodebuild -scheme FourDRayVisionViewer \
  -sdk xrsimulator \
  -destination 'generic/platform=visionOS Simulator' \
  build
```

Expected: `FourDRayCoreTests` passes, `FourDRayProbe` writes:

- `tmp/four-d-ray-probe-ana-mid-slice.ppm`
- `tmp/four-d-ray-probe-ana-contact-sheet.ppm`
- `tmp/four-d-ray-probe-volume-point-cloud.ply`

`FourDRayVisionViewer` prints its macOS fallback instructions, and the Xcode visionOS simulator build succeeds. Last verified 2026-05-28 after installing the visionOS simulator runtime.

## Next Action

Work `todos/005-ready-p1-wrap-viewer-in-visionos-app-bundle.md`: add a real visionOS app-bundle/project path, then install/launch it on `Skunkworks Vision Pro` or physical Vision Pro hardware.
