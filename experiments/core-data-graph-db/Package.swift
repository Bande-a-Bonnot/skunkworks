// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CoreDataGraphDB",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CoreDataGraphDB", targets: ["CoreDataGraphDB"]),
        .executable(name: "CoreDataGraphDBBenchmark", targets: ["CoreDataGraphDBBenchmark"]),
    ],
    targets: [
        .target(name: "CoreDataGraphDB"),
        .executableTarget(
            name: "CoreDataGraphDBBenchmark",
            dependencies: ["CoreDataGraphDB"]
        ),
        .testTarget(
            name: "CoreDataGraphDBTests",
            dependencies: ["CoreDataGraphDB"]
        ),
    ]
)
