// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SaynMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SaynMac", targets: ["SaynMac"])
    ],
    targets: [
        .executableTarget(
            name: "SaynMac",
            path: "Sources/SaynMac"
        )
    ]
)
