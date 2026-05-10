// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VectorToonz",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "VectorToonzCore", targets: ["VectorToonzCore"])
    ],
    targets: [
        .target(name: "VectorToonzCore"),
        .testTarget(name: "VectorToonzCoreTests", dependencies: ["VectorToonzCore"])
    ]
)
