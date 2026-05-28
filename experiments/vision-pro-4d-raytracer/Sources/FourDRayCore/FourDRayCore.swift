import Foundation
import simd

public typealias Vector3 = SIMD3<Float>
public typealias Vector4 = SIMD4<Float>

public struct Ray4: Sendable, Equatable {
    public var origin: Vector4
    public var direction: Vector4

    public init(origin: Vector4, direction: Vector4) {
        precondition(simd_length(direction) > 0, "Ray direction must be non-zero")
        self.origin = origin
        self.direction = simd_normalize(direction)
    }

    public func point(at distance: Float) -> Vector4 {
        origin + distance * direction
    }
}

public struct Hit4: Sendable, Equatable {
    public var distance: Float
    public var point: Vector4
    public var normal: Vector4

    public init(distance: Float, point: Vector4, normal: Vector4) {
        self.distance = distance
        self.point = point
        self.normal = simd_normalize(normal)
    }
}

public protocol Primitive4D: Sendable {
    func intersect(ray: Ray4, tMin: Float, tMax: Float) -> Hit4?
}

public struct Hypersphere: Primitive4D, Sendable, Equatable {
    public var center: Vector4
    public var radius: Float

    public init(center: Vector4, radius: Float) {
        precondition(radius > 0, "Hypersphere radius must be positive")
        self.center = center
        self.radius = radius
    }

    public func intersect(
        ray: Ray4,
        tMin: Float = 0.0001,
        tMax: Float = Float.greatestFiniteMagnitude
    ) -> Hit4? {
        let oc = ray.origin - center
        let a = simd_dot(ray.direction, ray.direction)
        let halfB = simd_dot(oc, ray.direction)
        let c = simd_dot(oc, oc) - radius * radius
        let discriminant = halfB * halfB - a * c

        guard discriminant >= 0 else { return nil }

        let sqrtDiscriminant = sqrt(discriminant)
        let roots = [
            (-halfB - sqrtDiscriminant) / a,
            (-halfB + sqrtDiscriminant) / a
        ]

        guard let distance = roots.first(where: { $0 >= tMin && $0 <= tMax }) else {
            return nil
        }

        let point = ray.point(at: distance)
        return Hit4(distance: distance, point: point, normal: point - center)
    }
}

public struct Hyperplane: Primitive4D, Sendable, Equatable {
    public var normal: Vector4
    public var offset: Float

    /// Defines the surface `dot(normal, p) + offset = 0`.
    public init(normal: Vector4, offset: Float) {
        let length = simd_length(normal)
        precondition(length > 0, "Hyperplane normal must be non-zero")
        self.normal = normal / length
        self.offset = offset / length
    }

    public func intersect(
        ray: Ray4,
        tMin: Float = 0.0001,
        tMax: Float = Float.greatestFiniteMagnitude
    ) -> Hit4? {
        let denominator = simd_dot(normal, ray.direction)
        guard abs(denominator) > 0.000001 else { return nil }

        let distance = -(simd_dot(normal, ray.origin) + offset) / denominator
        guard distance >= tMin && distance <= tMax else { return nil }

        return Hit4(distance: distance, point: ray.point(at: distance), normal: normal)
    }
}

public func reflect4D(direction: Vector4, around normal: Vector4) -> Vector4 {
    let unitDirection = simd_normalize(direction)
    let unitNormal = simd_normalize(normal)
    return simd_normalize(unitDirection - 2 * simd_dot(unitDirection, unitNormal) * unitNormal)
}

public enum StereoEye: Sendable, Equatable {
    case center
    case left
    case right

    public var offsetSign: Float {
        switch self {
        case .center: 0
        case .left: -0.5
        case .right: 0.5
        }
    }
}

public struct Camera4D: Sendable, Equatable {
    public var origin: Vector4
    public var right: Vector4
    public var up: Vector4
    public var forward: Vector4
    public var ana: Vector4
    public var focalLength: Float
    public var eyeSeparation: Float

    /// A pinhole camera with a 3D angular sensor embedded in 4D.
    ///
    /// Sensor coordinates are `(horizontal, vertical, ana)`:
    ///
    /// ```text
    /// d4 = normalize(focalLength * forward + x * right + y * up + z * ana)
    /// ```
    ///
    /// The `ana` axis is the fourth camera axis. Non-zero sensor `z` values send
    /// rays across the fourth spatial dimension instead of merely slicing at a
    /// fixed `w`.
    public init(
        origin: Vector4 = .zero,
        right: Vector4 = Vector4(1, 0, 0, 0),
        up: Vector4 = Vector4(0, 1, 0, 0),
        forward: Vector4 = Vector4(0, 0, 1, 0),
        ana: Vector4 = Vector4(0, 0, 0, 1),
        focalLength: Float = 1,
        eyeSeparation: Float = 0.064
    ) {
        precondition(focalLength > 0, "Focal length must be positive")
        precondition(eyeSeparation >= 0, "Eye separation must not be negative")

        self.origin = origin
        self.right = simd_normalize(right)
        self.up = simd_normalize(up)
        self.forward = simd_normalize(forward)
        self.ana = simd_normalize(ana)
        self.focalLength = focalLength
        self.eyeSeparation = eyeSeparation
    }

    public func ray(eye: StereoEye, sensor: Vector3) -> Ray4 {
        let eyeOrigin = origin + eye.offsetSign * eyeSeparation * right
        let direction = focalLength * forward + sensor.x * right + sensor.y * up + sensor.z * ana
        return Ray4(origin: eyeOrigin, direction: direction)
    }
}
