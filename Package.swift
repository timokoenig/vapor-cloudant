// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "VaporCloudant",
    products: [
        .library(name: "VaporCloudant", targets: ["VaporCloudant"])
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),

        // CouchDB adapter
        .package(url: "https://github.com/timokoenig/swift-cloudant.git", from: "0.8.1")
    ],
    targets: [
        .target(name: "VaporCloudant", dependencies: ["SwiftCloudant", "Vapor"]),
        .testTarget(name: "VaporCloudantTests", dependencies: ["VaporCloudant"])
    ]
)
