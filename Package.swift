// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CustomExecutorsKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "CustomExecutorsKit",
            targets: ["CustomExecutorsKit"]
        )
    ],
    targets: [
        .target(
            name: "CustomExecutorsKit",
            dependencies: [],
            path: "Sources/CustomExecutorsKit"
        ),
        .testTarget(
            name: "CustomExecutorsKitTests",
            dependencies: ["CustomExecutorsKit"],
            path: "Tests/CustomExecutorsKitTests"
        )
    ]
)
