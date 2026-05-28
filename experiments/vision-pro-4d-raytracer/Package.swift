// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VisionPro4DRaytracer",
    platforms: [
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "FourDRayCore", targets: ["FourDRayCore"])
    ],
    targets: [
        .target(name: "FourDRayCore"),
        .testTarget(name: "FourDRayCoreTests", dependencies: ["FourDRayCore"])
    ]
)
