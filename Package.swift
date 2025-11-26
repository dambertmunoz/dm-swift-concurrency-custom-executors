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
        ),
        .executable(
            name: "Demo",
            targets: ["Demo"]
        )
    ],
    targets: [
        .target(
            name: "CustomExecutorsKit",
            dependencies: [],
            path: "Sources/CustomExecutorsKit"
        ),
        .executableTarget(
            name: "Demo",
            dependencies: ["CustomExecutorsKit"],
            path: "Examples/Demo"
        ),
        .testTarget(
            name: "CustomExecutorsKitTests",
            dependencies: ["CustomExecutorsKit"],
            path: "Tests/CustomExecutorsKitTests"
        )
    ]
)
