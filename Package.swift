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
            name: "Property Carrier",
            targets: ["Property Carrier"]
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
            url: "https://github.com/swift-atoms/swift-ownership.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-tagged.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-carrier.git",
            branch: "main"
        ),
    ],
    targets: [

        .target(
            name: "Property",
            dependencies: []
        ),

        .target(
            name: "Property Carrier",
            dependencies: [
                .target(name: "Property"),
                .product(name: "Carrier Protocol", package: "swift-carrier"),
            ]
        ),

        .target(
            name: "Property Typed",
            dependencies: [
                .target(name: "Property")
            ]
        ),
        .target(
            name: "Property Consume",
            dependencies: [
                .target(name: "Property")
            ]
        ),
        .target(
            name: "Property Inout",
            dependencies: [
                .target(name: "Property"),
                .product(name: "Ownership Inout", package: "swift-ownership"),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),
        .target(
            name: "Property Borrow",
            dependencies: [
                .target(name: "Property"),
                .product(
                    name: "Ownership Borrow",
                    package: "swift-ownership"
                ),
                .product(name: "Tagged", package: "swift-tagged"),
            ]
        ),

        .testTarget(
            name: "Property Tests",
            dependencies: [
                .target(name: "Property"),
                .target(name: "Property Typed"),
                .target(name: "Property Test Support"),
            ]
        ),
        .testTarget(
            name: "Property Carrier Tests",
            dependencies: [
                .target(name: "Property"),
                .target(name: "Property Carrier"),
            ]
        ),
        .testTarget(
            name: "Property Typed Tests",
            dependencies: [
                .target(name: "Property Typed"),
                .target(name: "Property Test Support"),
            ]
        ),
        .testTarget(
            name: "Property Consume Tests",
            dependencies: [
                .target(name: "Property Consume"),
                .target(name: "Property Test Support"),
            ]
        ),
        .testTarget(
            name: "Property Inout Tests",
            dependencies: [
                .target(name: "Property Inout"),
                .target(name: "Property Test Support"),
            ]
        ),
        .testTarget(
            name: "Property Borrow Tests",
            dependencies: [
                .target(name: "Property Borrow"),
                .target(name: "Property Test Support"),
            ]
        ),

        .target(
            name: "Property Test Support",
            dependencies: [
                .target(name: "Property"),
                .target(name: "Property Typed"),
                .target(name: "Property Consume"),
                .target(name: "Property Inout"),
                .target(name: "Property Borrow"),
            ],
            path: "Tests/Property Test Support"
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
