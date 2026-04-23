// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-property-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(
            name: "Property Primitives",
            targets: ["Property Primitives"]
        ),
        .library(
            name: "Property Typed Primitives",
            targets: ["Property Typed Primitives"]
        ),
        .library(
            name: "Property Consuming Primitives",
            targets: ["Property Consuming Primitives"]
        ),
        .library(
            name: "Property View Primitives",
            targets: ["Property View Primitives"]
        ),
        .library(
            name: "Property View Read Primitives",
            targets: ["Property View Read Primitives"]
        ),
        .library(
            name: "Property Primitives Test Support",
            targets: ["Property Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-ownership-primitives"),
        .package(path: "../swift-tagged-primitives"),
    ],
    targets: [
        // MARK: - Core
        .target(
            name: "Property Primitives Core"
        ),

        // MARK: - Variants
        .target(
            name: "Property Typed Primitives",
            dependencies: [
                "Property Primitives Core",
            ]
        ),
        .target(
            name: "Property Consuming Primitives",
            dependencies: [
                "Property Primitives Core",
            ]
        ),
        .target(
            name: "Property View Primitives",
            dependencies: [
                "Property Primitives Core",
                .product(name: "Ownership Inout Primitives", package: "swift-ownership-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),
        .target(
            name: "Property View Read Primitives",
            dependencies: [
                "Property Primitives Core",
                "Property View Primitives",
                .product(name: "Ownership Borrow Primitives", package: "swift-ownership-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),

        // MARK: - Umbrella
        .target(
            name: "Property Primitives",
            dependencies: [
                "Property Primitives Core",
                "Property Typed Primitives",
                "Property Consuming Primitives",
                "Property View Primitives",
                "Property View Read Primitives",
            ]
        ),

        // MARK: - Tests
        .testTarget(
            name: "Property Primitives Core Tests",
            dependencies: [
                "Property Primitives Core",
                "Property Primitives Test Support",
            ],
            path: "Tests/Property Primitives Core Tests"
        ),
        .testTarget(
            name: "Property Typed Primitives Tests",
            dependencies: [
                "Property Typed Primitives",
                "Property Primitives Test Support",
            ],
            path: "Tests/Property Typed Primitives Tests"
        ),
        .testTarget(
            name: "Property Consuming Primitives Tests",
            dependencies: [
                "Property Consuming Primitives",
                "Property Primitives Test Support",
            ],
            path: "Tests/Property Consuming Primitives Tests"
        ),
        .testTarget(
            name: "Property View Primitives Tests",
            dependencies: [
                "Property View Primitives",
                "Property Primitives Test Support",
            ],
            path: "Tests/Property View Primitives Tests"
        ),
        .testTarget(
            name: "Property View Read Primitives Tests",
            dependencies: [
                "Property View Read Primitives",
                "Property Primitives Test Support",
            ],
            path: "Tests/Property View Read Primitives Tests"
        ),

        // MARK: - Tutorial Verification
        // Mirrors the final step of the Getting Started tutorial so that API
        // drift breaks the test suite. Per [DOC-073] verification option A.
        .testTarget(
            name: "Property Primitives Tutorial Tests",
            dependencies: [
                "Property Primitives",
            ],
            path: "Tests/Tutorial"
        ),

        // MARK: - Test Support
        .target(
            name: "Property Primitives Test Support",
            dependencies: [
                "Property Primitives",
            ],
            path: "Tests/Support"
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
