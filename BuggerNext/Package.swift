// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Bugger",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Bugger",
            targets: ["Bugger"]
        ),
        .library(
            name: "BuggerGitHub",
            targets: ["BuggerGitHub"]
        )
    ],
    targets: [
        .target(
            name: "Bugger",
            path: "Sources/Bugger",
        ),
        .target(
            name: "BuggerGitHub",
            dependencies: ["Bugger"],
            path: "Sources/BuggerGitHub"
        )
    ]
)
