// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-property",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Property",
            targets: ["Property"]
        ),
        .library(
            name: "Property Standard Library Integration",
            targets: ["Property Standard Library Integration"]
        ),
        .library(
            name: "Property Apple Foundation Integration",
            targets: ["Property Apple Foundation Integration"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Property",
            dependencies: []
        ),
        .target(
            name: "Property Standard Library Integration",
            dependencies: ["Property"]
        ),
        .target(
            name: "Property Apple Foundation Integration",
            dependencies: [
                "Property",
                "Property Standard Library Integration",
            ]
        ),
        .testTarget(
            name: "Property Tests",
            dependencies: ["Property"],
            path: "Tests/Property Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
