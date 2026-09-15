// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CognitiveLint",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "cognitive-check", targets: ["CognitiveCheck"])],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "603.0.2")
    ],
    targets: [
        .target(
            name: "CognitiveLint",
            dependencies: [.product(name: "SwiftSyntax", package: "swift-syntax")]
        ),
        .executableTarget(
            name: "CognitiveCheck",
            dependencies: ["CognitiveLint", .product(name: "SwiftParser", package: "swift-syntax")]
        ),
        .testTarget(
            name: "CognitiveLintTests",
            dependencies: [
                "CognitiveLint",
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax")
            ],
            path: "Tests"
        )
    ]
)
