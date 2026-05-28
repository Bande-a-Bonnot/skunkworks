# Volume Inspection Path Findings

**Date:** 2026-05-28  
**Status:** first non-flat inspection/export path working

## Decision

Use a simple macOS command-line export path before creating a full visionOS app. `FourDRayProbe` still renders a Metal `64 x 64 x 32` 3D texture, but now exports multiple ways to inspect that volume:

```bash
cd experiments/vision-pro-4d-raytracer
swift run FourDRayProbe
```

Outputs:

```text
tmp/four-d-ray-probe-ana-mid-slice.ppm
tmp/four-d-ray-probe-ana-contact-sheet.ppm
tmp/four-d-ray-probe-volume-point-cloud.ply
```

## Why This Stack

This is not the final Vision Pro viewer, but it preserves the intended dimensional split while keeping iteration fast:

- Metal still traces through 4D.
- The output remains a 3D projected volume over `(u, v, ana)`.
- The contact sheet gives quick 2D debugging across multiple `ana` layers.
- The PLY point cloud turns the projection volume into ordinary 3D spatial data that can be inspected in Blender, MeshLab, or converted later for RealityKit/visionOS.

## Output Semantics

The point-cloud coordinates are:

```text
x = u      // camera horizontal sensor coordinate
y = v      // camera vertical sensor coordinate, flipped so positive y is up
z = ana    // angular sample into the fourth camera axis
```

Color is copied from the Metal radiance volume. Every voxel is exported as a vertex for now, producing `131072` vertices at the current resolution.

Important: `z` in the PLY is not ordinary world depth. It is the 4D camera's `ana`/fourth-axis sensor coordinate. This keeps the 4D-to-3D projection explicit.

## Verification

Passed on 2026-05-28:

```bash
swift test
swift run FourDRayProbe
```

Observed Metal device: `Apple Paravirtual device`.

## Next Step

Build an actual viewer/app path around the exported volume:

- a small RealityKit/visionOS point-cloud viewer, or
- a macOS SwiftUI/MetalKit volume inspector if Vision Pro project setup is still too heavy.
