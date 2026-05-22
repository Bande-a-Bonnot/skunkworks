// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CoreDataRESTLayer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "CoreDataRESTLayer",
            targets: ["CoreDataRESTLayer"]
        ),
        .library(
            name: "CoreDataRESTLayerTestServer",
            targets: ["CoreDataRESTLayerTestServer"]
        )
    ],
    targets: [
        .target(
            name: "CoreDataRESTLayer"
        ),
        .target(
            name: "CoreDataRESTLayerTestServer",
            dependencies: ["CoreDataRESTLayer"]
        ),
        .testTarget(
            name: "CoreDataRESTLayerTests",
            dependencies: [
                "CoreDataRESTLayer",
                "CoreDataRESTLayerTestServer"
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
