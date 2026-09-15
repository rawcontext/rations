// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RationsPackages",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "RationsCore", targets: ["RationsCore"]),
        .library(name: "RationsProviders", targets: ["RationsProviders"])
    ],
    targets: [
        .target(name: "RationsCore", path: "core/Sources"),
        .target(name: "RationsProviders", dependencies: ["RationsCore"], path: "providers/Sources"),
        .testTarget(name: "RationsCoreTests", dependencies: ["RationsCore"], path: "core/Tests"),
        .testTarget(
            name: "RationsProvidersTests",
            dependencies: ["RationsProviders", "RationsCore"],
            path: "providers/Tests"
        )
    ]
)
