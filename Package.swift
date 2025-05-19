// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Remedios",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Remedios",
            targets: ["Remedios"]
        )
    ],
    targets: [
        .target(
            name: "Remedios",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
