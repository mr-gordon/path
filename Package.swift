// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "path",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "PathCore"),
        .executableTarget(name: "path", dependencies: ["PathCore"]),
        .testTarget(name: "PathCoreTests", dependencies: ["PathCore"]),
    ]
)
