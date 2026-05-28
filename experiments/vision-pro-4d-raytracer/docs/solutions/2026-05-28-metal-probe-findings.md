# Metal Probe Findings

**Date:** 2026-05-28  
**Status:** first GPU proof working on macOS Metal

## What Exists

`FourDRayProbe` is a Swift Package executable that compiles an in-memory Metal compute kernel and renders a tiny 4D-projected volume:

```bash
cd experiments/vision-pro-4d-raytracer
swift run FourDRayProbe
```

Current output:

```text
tmp/four-d-ray-probe-ana-mid-slice.ppm
```

The full GPU target is a `64 x 64 x 32` `rgba8Unorm` 3D texture. The executable reads it back and writes the middle `ana` slice as a quick PPM debug artifact.

## Kernel Shape

The kernel uses `float4` for:

- ray origin;
- ray direction;
- hypersphere center/point/normal;
- hyperplane normal;
- reflected bounce direction.

Projection volume coordinates are interpreted as `(u, v, ana)`:

```text
direction = normalize(float4(u, v, 1, ana))
```

That means different depth layers in the 3D texture are not ordinary z-depth slices; they are angular samples into the fourth camera axis.

## Scene

- Primary primitive: hypersphere centered at the origin with radius `1`.
- Bounce primitive: hyperplane with a mixed `y/w` normal.
- Shading: normal-color base with a reflected hyperplane checker when the one-bounce ray hits.

## Verification

Passed on 2026-05-28:

```bash
swift test
swift run FourDRayProbe
```

Observed Metal device: `Apple Paravirtual device`.

## Notes

- The shader currently lives as a Swift raw string for fast iteration. Move it to a `.metal` file when the project shape stabilizes.
- The output is not a Vision Pro viewer yet; it is the first GPU-generated 3D volume/probe artifact.
