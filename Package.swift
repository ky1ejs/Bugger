// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bugger",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "Bugger", targets: ["Bugger"]),
        .library(name: "BuggerGitHub", targets: ["BuggerGitHub"]),
        .library(name: "BuggerImgurStore", targets: ["BuggerImgurStore"]),
        .library(name: "BuggerLinear", targets: ["BuggerLinear"]),
        .library(name: "HelpfulUI", targets: ["HelpfulUI"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "Bugger",dependencies: []),
        .target(name: "BuggerGitHub", dependencies: ["Bugger"]),
        .target(name: "BuggerImgurStore", dependencies: []),
        .target(name: "BuggerLinear", dependencies: ["Bugger"]),
        .target(name: "HelpfulUI", dependencies: []),
        .testTarget(name: "BuggerTests",dependencies: ["Bugger"]),
    ]
)
