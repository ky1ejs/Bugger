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
        )
    ],
    targets: [
        .target(
            name: "Bugger",
            path: "Sources/Bugger",
        )
    ]
)
