// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ShishutsukanKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "ShishutsukanKit", targets: ["ShishutsukanKit"])
    ],
    targets: [
        .target(
            name: "ShishutsukanKit",
            path: "Sources/ShishutsukanKit"
        ),
        .testTarget(
            name: "ShishutsukanKitTests",
            dependencies: ["ShishutsukanKit"],
            path: "Tests/ShishutsukanKitTests"
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: ["ShishutsukanKit"],
            path: "Tests/IntegrationTests"
        )
    ]
)