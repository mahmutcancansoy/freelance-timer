// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FreelanceTimer",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "FreelanceTimer", targets: ["FreelanceTimer"])
    ],
    targets: [
        .executableTarget(
            name: "FreelanceTimer",
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "FreelanceTimerTests",
            dependencies: ["FreelanceTimer"],
            path: "Tests"
        )
    ]
)
