// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "NIOAsync",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .library(name: "NIOAsync", targets: ["NIOAsync"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/belozierov/SwiftCoroutine.git", from: "2.0.5")
    ],
    targets: [
        .target(name: "NIOAsync", dependencies: ["NIO", "SwiftCoroutine"]),
        .testTarget(name: "NIOAsyncTests", dependencies: ["NIOAsync", "NIO"]),
    ]
)
