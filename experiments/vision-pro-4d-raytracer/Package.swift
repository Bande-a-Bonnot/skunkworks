// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VisionPro4DRaytracer",
    platforms: [
        .macOS(.v15),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "FourDRayCore", targets: ["FourDRayCore"]),
        .executable(name: "FourDRayProbe", targets: ["FourDRayProbe"])
    ],
    targets: [
        .target(name: "FourDRayCore"),
        .executableTarget(name: "FourDRayProbe"),
        .testTarget(name: "FourDRayCoreTests", dependencies: ["FourDRayCore"])
    ]
)
