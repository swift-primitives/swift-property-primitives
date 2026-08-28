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
            name: "Property Primitive",
            targets: ["Property Primitive"]
        ),
        .library(
            name: "Property Carrier",
            targets: ["Property Carrier"]
        ),
        .library(
            name: "Property",
            targets: ["Property"]
        ),
        .library(
            name: "Property Typed",
            targets: ["Property Typed"]
        ),
        .library(
            name: "Property Consume",
            targets: ["Property Consume"]
        ),
        .library(
            name: "Property Inout",
            targets: ["Property Inout"]
        ),
        .library(
            name: "Property Borrow",
            targets: ["Property Borrow"]
        ),
        .library(
            name: "Property Test Support",
            targets: ["Property Test Support"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-ownership.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-tagged.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-carrier.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Property Primitive"
        ),

        .target(
            name: "Property Carrier",
            dependencies: [
                "Property Primitive",
                .product(name: "Carrier", package: "swift-carrier"),
            ]
        ),

        .target(
            name: "Property Typed",
            dependencies: [
                "Property Primitive"
            ]
        ),
        .target(
            name: "Property Consume",
            dependencies: [
                "Property Primitive"
            ]
        ),
        .target(
            name: "Property Inout",
            dependencies: [
                "Property Primitive",
                .product(name: "Ownership Inout", package: "swift-ownership"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Property Borrow",
            dependencies: [
                "Property Primitive",
                .product(
                    name: "Ownership Borrow",
                    package: "swift-ownership"
                ),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),

        .target(
            name: "Property",
            dependencies: [
                "Property Primitive",
                "Property Carrier",
                "Property Typed",
                "Property Consume",
                "Property Inout",
                "Property Borrow",
            ]
        ),

        .testTarget(
            name: "Property Primitive Tests",
            dependencies: [
                "Property Primitive",
                "Property Test Support",
            ],
            path: "Tests/Property Primitive Tests"
        ),
        .testTarget(
            name: "Property Typed Tests",
            dependencies: [
                "Property Typed",
                "Property Test Support",
            ],
            path: "Tests/Property Typed Tests"
        ),
        .testTarget(
            name: "Property Consume Tests",
            dependencies: [
                "Property Consume",
                "Property Test Support",
            ],
            path: "Tests/Property Consume Tests"
        ),
        .testTarget(
            name: "Property Inout Tests",
            dependencies: [
                "Property Inout",
                "Property Test Support",
            ],
            path: "Tests/Property Inout Tests"
        ),
        .testTarget(
            name: "Property Borrow Tests",
            dependencies: [
                "Property Borrow",
                "Property Test Support",
            ],
            path: "Tests/Property Borrow Tests"
        ),

        .testTarget(
            name: "Property Tutorial Tests",
            dependencies: [
                "Property"
            ],
            path: "Tests/Tutorial"
        ),

        .target(
            name: "Property Test Support",
            dependencies: [
                "Property",
                .product(
                    name: "Ownership Test Support",
                    package: "swift-ownership"
                ),
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
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
