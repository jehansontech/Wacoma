// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Wacoma",
    platforms: [
        .macOS(.v11), .iOS(.v14)
    ],
    products: [
        .library(
            name: "Wacoma",
            targets: ["Wacoma"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Wacoma",
            dependencies: []),
        .testTarget(
            name: "WacomaTests",
            dependencies: ["Wacoma"]),
    ]
)
