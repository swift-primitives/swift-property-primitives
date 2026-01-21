// swift-tools-version: 6.2
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
        )
    ],
    targets: [
        .target(
            name: "Property Primitives",
            swiftSettings: [
                .enableExperimentalFeature("Lifetimes")
            ]
        ),
        .testTarget(
            name: "Property Primitives Tests",
            dependencies: ["Property Primitives"]
        )
    ]
)
