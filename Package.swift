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
            name: "Property Consume Primitives",
            targets: ["Property Consume Primitives"]
        ),
        .library(
            name: "Property Inout Primitives",
            targets: ["Property Inout Primitives"]
        ),
        .library(
            name: "Property Borrow Primitives",
            targets: ["Property Borrow Primitives"]
        ),
        .library(
            name: "Property Primitives Test Support",
            targets: ["Property Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-ownership-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-carrier-primitives.git", branch: "main"),
    ],
    targets: [
        // MARK: - Core
        .target(
            name: "Property Primitives Core",
            dependencies: [
                .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
            ]
        ),

        // MARK: - Variants
        .target(
            name: "Property Typed Primitives",
            dependencies: [
                "Property Primitives Core",
            ]
        ),
        .target(
            name: "Property Consume Primitives",
            dependencies: [
                "Property Primitives Core",
            ]
        ),
        .target(
            name: "Property Inout Primitives",
            dependencies: [
                "Property Primitives Core",
                .product(name: "Ownership Inout Primitives", package: "swift-ownership-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
            ]
        ),
        .target(
            name: "Property Borrow Primitives",
            dependencies: [
                "Property Primitives Core",
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
                "Property Consume Primitives",
                "Property Inout Primitives",
                "Property Borrow Primitives",
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
            name: "Property Consume Primitives Tests",
            dependencies: [
                "Property Consume Primitives",
                "Property Primitives Test Support",
            ],
            path: "Tests/Property Consume Primitives Tests"
        ),
        .testTarget(
            name: "Property Inout Primitives Tests",
            dependencies: [
                "Property Inout Primitives",
                "Property Primitives Test Support",
            ],
            path: "Tests/Property Inout Primitives Tests"
        ),
        .testTarget(
            name: "Property Borrow Primitives Tests",
            dependencies: [
                "Property Borrow Primitives",
                "Property Primitives Test Support",
            ],
            path: "Tests/Property Borrow Primitives Tests"
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
                .product(name: "Ownership Primitives Test Support", package: "swift-ownership-primitives"),
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
