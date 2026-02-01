// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RssReaderMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RssReaderMac",
            targets: ["RssReaderMac"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/nmdias/FeedKit.git", exact: "9.1.2"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", exact: "2.6.0")
    ],
    targets: [
        .target(
            name: "RssReaderMac",
            dependencies: ["FeedKit", "SwiftSoup"],
            path: "RssReaderMac",
            exclude: ["Resources"],
            sources: [
                "Models",
                "Services"
            ]
        ),
        .testTarget(
            name: "RssReaderMacTests",
            dependencies: ["RssReaderMac"],
            path: "RssReaderMacTests"
        )
    ]
)
