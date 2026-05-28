# Camera / Projection Model v0

**Date:** 2026-05-26  
**Status:** implemented in `FourDRayCore` CPU checks

## Decision

Start with a 4D pinhole renderer that writes a **3D projected radiance volume**. Vision Pro can later inspect that volume stereoscopically with an ordinary binocular 3D camera.

This keeps the requested dimensional split explicit:

- tracing space: 4D;
- projected output: 3D volume;
- human display: binocular/stereo 3D on Vision Pro.

Direct per-eye 2D render targets remain a fallback, but the first Metal target should be one or two 3D textures, not a flat image.

## Camera Embedding

The camera has a 4D origin and an orthonormal-ish frame:

```text
right   = x camera axis in R4
up      = y camera axis in R4
forward = main look axis in R4
ana     = fourth/extra camera axis in R4
```

The default basis is:

```text
right   = (1, 0, 0, 0)
up      = (0, 1, 0, 0)
forward = (0, 0, 1, 0)
ana     = (0, 0, 0, 1)
```

A stereo eye shifts the 4D origin along `right` using ordinary interpupillary distance:

```text
eyeOrigin(left)  = origin - 0.5 * IPD * right
eyeOrigin(right) = origin + 0.5 * IPD * right
```

Both eyes initially sit at the same `w` coordinate. Fourth-dimensional separation can be explored later as an artistic/non-human mode.

## 3D Projection Sensor

A projected volume cell has sensor coordinates:

```text
s = (u, v, a)
```

where:

- `u` spans the camera `right` axis;
- `v` spans the camera `up` axis;
- `a` spans the `ana` axis, which controls angular travel into the fourth dimension.

Ray generation:

```text
d4 = normalize(focalLength * forward + u * right + v * up + a * ana)
r(t) = eyeOrigin + t * d4
```

A non-zero `a` produces a ray with fourth-dimensional direction. A 3D texture can store traced radiance over `(u, v, a)`.

## Primitive Formulas

### Hypersphere / 3-sphere boundary

```text
F(p) = dot(p - c, p - c) - r^2
normal = normalize(p - c)
```

Substitute `p = o + t d`:

```text
a = dot(d, d)
b = 2 dot(o - c, d)
cq = dot(o - c, o - c) - r^2
discriminant = b^2 - 4 a cq
```

The implementation uses the numerically equivalent half-`b` form.

### Hyperplane

```text
F(p) = dot(n, p) + b
normal = normalize(n)
t = -(dot(n, o) + b) / dot(n, d)
```

## 4D Reflection

Perfect mirror reflection is dimension-independent:

```text
d' = normalize(d - 2 dot(d, n) n)
```

The important part is that `d`, `n`, and `dot` are all 4D. A ray can therefore bounce across the `w`/`ana` axis just like it can across `x/y/z`.

## CPU Checks

Implemented in `Tests/FourDRayCoreTests/FourDRayCoreTests.swift`:

- hypersphere hit at expected distance;
- hypersphere miss caused solely by `w` offset;
- hyperplane hit using a `w` normal;
- reflection flips the 4D normal component while preserving length;
- stereo camera origins shift by IPD and generated rays can have non-zero `w` direction.

Run:

```bash
cd experiments/vision-pro-4d-raytracer
swift test
```
