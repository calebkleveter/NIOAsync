// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "NIOCoroutines",
    products: [
        .library(name: "NIOCoroutines", targets: ["NIOCoroutines"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/belozierov/SwiftCoroutine.git", from: "1.0.5")
    ],
    targets: [
        .target(name: "NIOCoroutines", dependencies: ["NIO", "SwiftCoroutine"]),
        .testTarget(name: "NIOCoroutinesTests", dependencies: ["NIOCoroutines", "NIO"]),
    ]
)
