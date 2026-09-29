// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TimestampTranscriber",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "Timestamp", targets: ["Timestamp"]),
    ],
    targets: [
        .executableTarget(
            name: "Timestamp",
            path: "Sources/Timestamp"
        ),
    ]
)
