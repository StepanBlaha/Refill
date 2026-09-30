// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Refill",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Refill", path: "Sources/Refill"),
        .testTarget(name: "RefillTests", dependencies: ["Refill"], path: "Tests/RefillTests")
    ]
)
