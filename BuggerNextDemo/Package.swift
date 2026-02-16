// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BuggerNextDemo",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "BuggerNextDemo",
            targets: ["BuggerNextDemoApp"]
        )
    ],
    dependencies: [
        .package(path: "../BuggerNext")
    ],
    targets: [
        .executableTarget(
            name: "BuggerNextDemoApp",
            dependencies: ["Bugger"]
        )
    ]
)
