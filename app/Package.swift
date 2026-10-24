// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LiveCaptioner",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio", exact: "0.17.4"),
        // Its manifest needs swift-tools-version 6.2, so Xcode 26+.
        .package(url: "https://github.com/jaywcjlove/PermissionFlow", exact: "2.11.2"),
    ],
    targets: [
        .executableTarget(
            name: "LiveCaptioner",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "PermissionFlow", package: "PermissionFlow"),
            ],
            path: "Sources/Parakeet"
        )
    ],
    swiftLanguageModes: [.v5]
)
