// swift-tools-version: 6.2

import PackageDescription

// Matches the app's concurrency settings.
let swiftSettings: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("InferSendableFromCaptures"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

let package = Package(
    name: "SwingKit",
    platforms: [.macOS(.v15), .iOS(.v18)],
    products: [
        .library(name: "SwingKit", targets: ["SwingKit"]),
    ],
    targets: [
        .target(name: "SwingKit", swiftSettings: swiftSettings),
        .testTarget(name: "SwingKitTests", dependencies: ["SwingKit"], swiftSettings: swiftSettings),
    ],
    swiftLanguageModes: [.v5]
)
