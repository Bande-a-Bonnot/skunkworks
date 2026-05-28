import XCTest
import simd
@testable import FourDRayCore

final class FourDRayCoreTests: XCTestCase {
    func testHypersphereIntersectionUsesFourDimensionalDistance() throws {
        let sphere = Hypersphere(center: Vector4(0, 0, 0, 0), radius: 1)
        let ray = Ray4(origin: Vector4(-3, 0, 0, 0), direction: Vector4(1, 0, 0, 0))

        let hit = try XCTUnwrap(sphere.intersect(ray: ray))

        XCTAssertEqual(hit.distance, 2, accuracy: 0.0001)
        XCTAssertVector(hit.point, Vector4(-1, 0, 0, 0), accuracy: 0.0001)
        XCTAssertVector(hit.normal, Vector4(-1, 0, 0, 0), accuracy: 0.0001)
    }

    func testHypersphereIntersectionCanBeMissedThroughW() {
        let sphere = Hypersphere(center: Vector4(0, 0, 0, 0), radius: 1)
        let ray = Ray4(origin: Vector4(-3, 0, 0, 2), direction: Vector4(1, 0, 0, 0))

        XCTAssertNil(sphere.intersect(ray: ray))
    }

    func testHyperplaneIntersectionSupportsWNormal() throws {
        let plane = Hyperplane(normal: Vector4(0, 0, 0, 1), offset: -2)
        let ray = Ray4(origin: Vector4(0, 0, 0, 0), direction: Vector4(0, 0, 0, 1))

        let hit = try XCTUnwrap(plane.intersect(ray: ray))

        XCTAssertEqual(hit.distance, 2, accuracy: 0.0001)
        XCTAssertVector(hit.point, Vector4(0, 0, 0, 2), accuracy: 0.0001)
        XCTAssertVector(hit.normal, Vector4(0, 0, 0, 1), accuracy: 0.0001)
    }

    func testReflectionFlipsNormalComponentInFourDimensions() {
        let incoming = simd_normalize(Vector4(0, -1, 0, -1))
        let normal = Vector4(0, 0, 0, 1)

        let reflected = reflect4D(direction: incoming, around: normal)

        XCTAssertEqual(simd_length(reflected), 1, accuracy: 0.0001)
        XCTAssertEqual(simd_dot(reflected, normal), -simd_dot(incoming, normal), accuracy: 0.0001)
        XCTAssertEqual(reflected.y, incoming.y, accuracy: 0.0001)
        XCTAssertGreaterThan(reflected.w, 0)
    }

    func testCameraGeneratesStereoFourDimensionalRays() {
        let camera = Camera4D(eyeSeparation: 0.064)

        let left = camera.ray(eye: .left, sensor: Vector3(0, 0, 0.5))
        let right = camera.ray(eye: .right, sensor: Vector3(0, 0, 0.5))

        XCTAssertVector(left.origin, Vector4(-0.032, 0, 0, 0), accuracy: 0.0001)
        XCTAssertVector(right.origin, Vector4(0.032, 0, 0, 0), accuracy: 0.0001)
        XCTAssertEqual(simd_length(left.direction), 1, accuracy: 0.0001)
        XCTAssertEqual(simd_length(right.direction), 1, accuracy: 0.0001)
        XCTAssertGreaterThan(left.direction.w, 0)
        XCTAssertGreaterThan(right.direction.w, 0)
    }
}

private func XCTAssertVector(
    _ actual: Vector4,
    _ expected: Vector4,
    accuracy: Float,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(actual.x, expected.x, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.y, expected.y, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.z, expected.z, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.w, expected.w, accuracy: accuracy, file: file, line: line)
}
