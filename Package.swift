// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UIStuffForSwift",
    platforms: [
        .macOS(.v11), .iOS(.v14)
    ],
    products: [
        .library(
            name: "Taconic",
            targets: ["Taconic"]),
        .library(
            name: "UIStuffForSwift",
            targets: ["UIStuffForSwift"]),
    ],
    dependencies: [
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Taconic",
            dependencies: []),
        .target(
            name: "UIStuffForSwift",
            dependencies: ["Taconic"]),
        .testTarget(
            name: "TaconicTests",
            dependencies: ["Taconic"]),
        .testTarget(
            name: "UIStuffForSwiftTests",
            dependencies: ["UIStuffForSwift"])
    ]
)
