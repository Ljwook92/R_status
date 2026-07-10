// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RStudioStatus",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "RStudioStatus", targets: ["RStudioStatus"])
    ],
    targets: [
        .executableTarget(
            name: "RStudioStatus",
            path: "Sources/RStudioStatus"
        )
    ]
)
