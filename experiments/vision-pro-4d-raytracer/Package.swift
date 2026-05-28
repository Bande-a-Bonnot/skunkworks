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
        .executable(name: "FourDRayProbe", targets: ["FourDRayProbe"]),
        .executable(name: "FourDRayVisionViewer", targets: ["FourDRayVisionViewer"])
    ],
    targets: [
        .target(name: "FourDRayCore"),
        .executableTarget(name: "FourDRayProbe"),
        .executableTarget(name: "FourDRayVisionViewer"),
        .testTarget(name: "FourDRayCoreTests", dependencies: ["FourDRayCore"])
    ]
)
