// swift-tools-version: 5.9
// macOS-only WKWebView demo; depends on the repo-root Fountain Swift package.
import PackageDescription

let package = Package(
    name: "FountainSampleMac",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "FountainSampleMac", targets: ["FountainSampleMac"]),
    ],
    dependencies: [
        .package(name: "FountainSwiftPM", path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "FountainSampleMac",
            dependencies: [
                .product(name: "Fountain", package: "FountainSwiftPM"),
            ],
            path: "Sources/FountainSampleMac",
            resources: [.process("Resources")]
        ),
    ]
)
