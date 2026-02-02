// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bugger",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "Bugger", targets: ["Bugger"]),
        .library(name: "BuggerGitHub", targets: ["BuggerGitHub"]),
        .library(name: "BuggerImgurStore", targets: ["BuggerImgurStore"]),
        .library(name: "BuggerLinear", targets: ["BuggerLinear"]),
        .library(name: "HelpfulUI", targets: ["HelpfulUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "Bugger",
            dependencies: [],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .target(
            name: "BuggerGitHub",
            dependencies: [
                "Bugger",
                "BuggerImgurStore",
                "HelpfulUI"
            ],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .target(
            name: "BuggerImgurStore",
            dependencies: ["Bugger"],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .target(
            name: "BuggerLinear",
            dependencies: [
                "Bugger",
                "HelpfulUI",
                .product(name: "Apollo", package: "apollo-ios"),
                .product(name: "ApolloAPI", package: "apollo-ios"),
            ],
            // Note: Swift 5 mode required due to Apollo-generated code not conforming to Sendable
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .target(
            name: "HelpfulUI",
            dependencies: [],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
        .testTarget(
            name: "BuggerTests",
            dependencies: ["Bugger", "BuggerGitHub"],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
        ),
    ]
)
