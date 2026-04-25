// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BacktesterNoteAlgorithms",
    platforms: [
        .iOS("17.4"),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "BacktesterNoteAlgorithms",
            targets: ["BacktesterNoteAlgorithms"]
        ),
    ],
    targets: [
        .target(
            name: "BacktesterNoteAlgorithms",
            path: "Sources/BacktesterNoteAlgorithms"
        ),
        .testTarget(
            name: "BacktesterNoteAlgorithmsTests",
            dependencies: ["BacktesterNoteAlgorithms"],
            path: "Tests/BacktesterNoteAlgorithmsTests"
        ),
    ]
)
