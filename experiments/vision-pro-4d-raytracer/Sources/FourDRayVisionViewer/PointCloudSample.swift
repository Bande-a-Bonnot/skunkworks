import Foundation
import simd

struct PointCloudPoint: Sendable, Equatable {
    var position: SIMD3<Float>
    var color: SIMD3<Float>
}

enum PointCloudSample {
    /// Generates a compact CPU mirror of the current Metal probe's projection volume.
    ///
    /// Coordinates preserve the projection-volume semantics:
    ///
    /// - `x = u`, horizontal camera sensor coordinate;
    /// - `y = v`, vertical camera sensor coordinate, flipped for display-up;
    /// - `z = ana`, angular sample into the fourth camera axis.
    static func generate(width: Int = 16, height: Int = 16, depth: Int = 8) -> [PointCloudPoint] {
        var points: [PointCloudPoint] = []
        points.reserveCapacity(width * height * depth)

        for z in 0..<depth {
            let ana = normalizedCoordinate(index: z, count: depth)
            for y in 0..<height {
                let v = normalizedCoordinate(index: y, count: height)
                for x in 0..<width {
                    let u = normalizedCoordinate(index: x, count: width)
                    let color = traceColor(u: u, v: v, ana: ana)
                    points.append(
                        PointCloudPoint(
                            position: SIMD3<Float>(u, -v, ana),
                            color: color
                        )
                    )
                }
            }
        }

        return points
    }

    private static func normalizedCoordinate(index: Int, count: Int) -> Float {
        ((Float(index) + 0.5) / Float(count)) * 2 - 1
    }

    private static func traceColor(u: Float, v: Float, ana: Float) -> SIMD3<Float> {
        let origin = SIMD4<Float>(0, 0, -3, 0)
        let direction = normalize(SIMD4<Float>(u, v, 1, ana))

        guard let primary = intersectHypersphere(origin: origin, direction: direction, center: .zero, radius: 1) else {
            let glow = 0.08 + 0.18 * abs(ana)
            return SIMD3<Float>(0.01, glow, 0.10 + 0.10 * abs(u))
        }

        let reflected = reflect4D(direction: direction, normal: primary.normal)
        let bounce = intersectHyperplane(
            origin: primary.point + 0.001 * reflected,
            direction: reflected,
            normal: normalize(SIMD4<Float>(0, 1, 0, 1)),
            offset: 1.35
        )

        let normalColor = SIMD3<Float>(
            0.5 + 0.5 * primary.normal.x,
            0.5 + 0.5 * primary.normal.y,
            0.5 + 0.5 * primary.normal.z
        )
        let wTint = 0.5 + 0.5 * primary.normal.w

        if let bounce {
            let checker = floor(bounce.point.x * 3) + floor(bounce.point.z * 3) + floor(bounce.point.w * 3)
            let t = checker.truncatingRemainder(dividingBy: 2)
            let planeColor = mix(SIMD3<Float>(1.0, 0.35, 0.10), SIMD3<Float>(0.10, 0.35, 1.0), t: t)
            return mix(normalColor, planeColor, t: 0.65)
        }

        return SIMD3<Float>(
            normalColor.x,
            normalColor.y * wTint,
            normalColor.z + 0.25 * wTint
        )
    }

    private static func intersectHypersphere(
        origin: SIMD4<Float>,
        direction: SIMD4<Float>,
        center: SIMD4<Float>,
        radius: Float
    ) -> Hit? {
        let oc = origin - center
        let a = dot(direction, direction)
        let halfB = dot(oc, direction)
        let c = dot(oc, oc) - radius * radius
        let discriminant = halfB * halfB - a * c

        guard discriminant >= 0 else { return nil }

        let root = sqrt(discriminant)
        var t = (-halfB - root) / a
        if t < 0.0001 {
            t = (-halfB + root) / a
        }
        guard t >= 0.0001 else { return nil }

        let point = origin + t * direction
        return Hit(point: point, normal: normalize(point - center))
    }

    private static func intersectHyperplane(
        origin: SIMD4<Float>,
        direction: SIMD4<Float>,
        normal: SIMD4<Float>,
        offset: Float
    ) -> Hit? {
        let n = normalize(normal)
        let denominator = dot(n, direction)
        guard abs(denominator) > 0.000001 else { return nil }

        let t = -(dot(n, origin) + offset) / denominator
        guard t >= 0.0001 else { return nil }

        return Hit(point: origin + t * direction, normal: n)
    }

    private static func reflect4D(direction: SIMD4<Float>, normal: SIMD4<Float>) -> SIMD4<Float> {
        let d = normalize(direction)
        let n = normalize(normal)
        return normalize(d - 2 * dot(d, n) * n)
    }

    private static func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        a * (1 - t) + b * t
    }

    private struct Hit {
        var point: SIMD4<Float>
        var normal: SIMD4<Float>
    }
}
