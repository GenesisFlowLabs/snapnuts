// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SnapNuts",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SnapNuts", targets: ["SnapNuts"])
    ],
    targets: [
        .executableTarget(
            name: "SnapNuts",
            path: "Sources/SnapNuts",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
