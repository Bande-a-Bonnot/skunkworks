# Initial Brainstorm: 4D Raytracer in Metal

**Date:** 2026-05-26

User prompt:

> A 4d raytracer in Metal, projecting in 3d, with a binocular "camera", for the vision pro. With rays traveling in the 4 dimensions (so reflection angles & co need to be adjusted as well: a ray should be able to bounce across 4d space).

## Interpretation

Build an experiment where 4D is not cosmetic. The ray state, hit math, normals, and bounce math all use `R4`. The final presentation should be compatible with Vision Pro, likely by either rendering a 3D projected volume that stereo eyes can inspect or by rendering direct per-eye views from a 4D binocular camera.

## Design Tensions

- A 4D raytracer naturally maps a 4D scene to a 3D sensor/hyperplane, but Vision Pro ultimately displays stereoscopic 2D images.
- Direct per-eye rendering is pragmatic but may feel like a 3D projection was skipped.
- A 3D volume output is conceptually appealing but can be more expensive and harder to make legible.
- Reflection is straightforward algebraically in any dimension, but visual intuition is not; debug views will matter.

## Good First Visuals

- Normal-color hypersphere slice/projection.
- Mirror hypersphere reflecting a colored hyperplane.
- Animated `w` sweep to reveal that rays/bounces are using the fourth dimension.
- Two-eye comparison where eye separation is in ordinary 3D while the scene includes `w` depth.
